import express from 'express';
import Stripe from 'stripe';
import * as admin from 'firebase-admin';

const router = express.Router();

// Initialize Stripe with your secret key
const stripe = new Stripe('sk_test_51RrleLLUAmVQpcCRnVfGLj2jUzNbkv1u9AeMwZSbBKJ2tpPmLHovJaSSaZhR7AAci37cB36eiQJ7NrHdOTJzOOcX00RQaDOwgn', {
  apiVersion: '2023-10-16',
});

// Create payment intent
router.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd', paymentMethodId, customerId } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount * 100, // Convert to cents
      currency,
      payment_method: paymentMethodId,
      customer: customerId,
      confirm: true,
      return_url: 'https://app-kviktime-se.web.app/create-account',
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      status: paymentIntent.status,
    });
  } catch (error: any) {
    console.error('Payment intent error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Create customer
router.post('/create-customer', async (req, res) => {
  try {
    const { email, name, phone } = req.body;

    const customer = await stripe.customers.create({
      email,
      name,
      phone,
    });

    res.json({ customerId: customer.id });
  } catch (error: any) {
    console.error('Customer creation error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Create subscription
router.post('/create-subscription', async (req, res) => {
  try {
    const { customerId, priceId, paymentMethodId } = req.body;

    // Attach payment method to customer
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customerId,
    });

    // Set as default payment method
    await stripe.customers.update(customerId, {
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    });

    // Create subscription
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ price: priceId }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent'],
    });

    res.json({
      subscriptionId: subscription.id,
      clientSecret: (subscription.latest_invoice as any)?.payment_intent?.client_secret,
    });
  } catch (error: any) {
    console.error('Subscription creation error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Complete account creation (Firebase Auth + Stripe)
// @ts-ignore
router.post('/create-account', async (req, res) => {
  try {
    const { email, password, name, phone, company, paymentMethodId } = req.body;
    
    console.log('Creating account for:', { email, name, phone, company });
    console.log('Payment method ID:', paymentMethodId);

    // Validate payment method first
    try {
      console.log('Validating payment method...');
      const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);
      console.log('Payment method retrieved:', {
        id: paymentMethod.id,
        type: paymentMethod.type,
        card: paymentMethod.card ? {
          brand: paymentMethod.card.brand,
          last4: paymentMethod.card.last4,
          expMonth: paymentMethod.card.exp_month,
          expYear: paymentMethod.card.exp_year
        } : null
      });
    } catch (pmError: any) {
      console.error('Payment method validation failed:', pmError);
      return res.status(400).json({ 
        error: 'Invalid payment method',
        details: pmError.message 
      });
    }

    // 1. Create Firebase Authentication user
    const userData: any = {
      email,
      password,
      displayName: name,
    };

    // Only add phone number if provided
    if (phone) userData.phoneNumber = phone;

    console.log('Creating Firebase user with data:', userData);
    const userRecord = await admin.auth().createUser(userData);
    console.log('Firebase user created:', userRecord.uid);

    // 2. Create Stripe customer
    const customerData: any = {
      email,
      name,
      metadata: {
        firebaseUid: userRecord.uid,
      },
    };

    // Only add phone if provided
    if (phone) customerData.phone = phone;

    console.log('Creating Stripe customer with data:', customerData);
    const customer = await stripe.customers.create(customerData);
    console.log('Stripe customer created:', customer.id);

    // 3. Attach payment method to customer
    console.log('Attaching payment method:', paymentMethodId);
    try {
      await stripe.paymentMethods.attach(paymentMethodId, {
        customer: customer.id,
      });
      console.log('Payment method attached successfully');
    } catch (attachError: any) {
      console.error('Payment method attachment failed:', attachError);
      // Clean up: delete the Firebase user and Stripe customer
      try {
        await admin.auth().deleteUser(userRecord.uid);
        await stripe.customers.del(customer.id);
      } catch (cleanupError) {
        console.error('Cleanup failed:', cleanupError);
      }
      return res.status(400).json({ 
        error: 'Failed to attach payment method',
        details: attachError.message 
      });
    }

    // 4. Set as default payment method
    console.log('Setting default payment method');
    try {
      await stripe.customers.update(customer.id, {
        invoice_settings: {
          default_payment_method: paymentMethodId,
        },
      });
      console.log('Default payment method set successfully');
    } catch (defaultError: any) {
      console.error('Setting default payment method failed:', defaultError);
      // Continue anyway, this is not critical
    }

    // 5. Create subscription
    console.log('Creating subscription with price:', 'price_1Rrm0vLUAmVQpcCRPCe9XF18');
    let subscription: any;
    try {
      subscription = await stripe.subscriptions.create({
        customer: customer.id,
        items: [{ price: 'price_1Rrm0vLUAmVQpcCRPCe9XF18' }], // Your 150 SEK price
        payment_behavior: 'default_incomplete',
        payment_settings: { save_default_payment_method: 'on_subscription' },
        expand: ['latest_invoice.payment_intent'],
      });
      console.log('Stripe subscription created:', subscription.id, 'Status:', subscription.status);
    } catch (subError: any) {
      console.error('Subscription creation failed:', subError);
      // Clean up: delete the Firebase user and Stripe customer
      try {
        await admin.auth().deleteUser(userRecord.uid);
        await stripe.customers.del(customer.id);
      } catch (cleanupError) {
        console.error('Cleanup failed:', cleanupError);
      }
      return res.status(400).json({ 
        error: 'Failed to create subscription',
        details: subError.message 
      });
    }

    // 6. Store user profile in Firestore
    const userProfile: any = {
      email,
      name,
      stripeCustomerId: customer.id,
      stripeSubscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Only add optional fields if they have values
    if (phone) userProfile.phone = phone;
    if (company) userProfile.company = company;

    console.log('Storing user profile in Firestore:', userProfile);
    await admin.firestore().collection('users').doc(userRecord.uid).set(userProfile);

    return res.json({
      success: true,
      userId: userRecord.uid,
      customerId: customer.id,
      subscriptionId: subscription.id,
      clientSecret: (subscription.latest_invoice as any)?.payment_intent?.client_secret,
    });
  } catch (error: any) {
    console.error('Account creation error:', error);
    console.error('Error details:', {
      message: error.message,
      type: error.type,
      code: error.code,
      statusCode: error.statusCode,
      stack: error.stack
    });
    res.status(400).json({ 
      error: error.message,
      type: error.type,
      code: error.code
    });
  }
});

// Get subscription plans
router.get('/plans', async (req, res) => {
  try {
    const prices = await stripe.prices.list({
      active: true,
      expand: ['data.product'],
    });

    const plans = prices.data.map(price => ({
      id: price.id,
      productId: (price.product as any)?.id,
      nickname: price.nickname,
      unitAmount: price.unit_amount,
      currency: price.currency,
      recurring: price.recurring,
      product: {
        name: (price.product as any)?.name,
        description: (price.product as any)?.description,
      },
    }));

    res.json(plans);
  } catch (error: any) {
    console.error('Plans fetch error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Test specific price ID
router.get('/test-price/:priceId', async (req, res) => {
  try {
    const { priceId } = req.params;
    console.log('Testing price ID:', priceId);
    
    const price = await stripe.prices.retrieve(priceId);
    console.log('Price found:', price);
    
    res.json({
      exists: true,
      price: {
        id: price.id,
        active: price.active,
        unitAmount: price.unit_amount,
        currency: price.currency,
        recurring: price.recurring,
        nickname: price.nickname
      }
    });
  } catch (error: any) {
    console.error('Price test error:', error);
    res.status(400).json({ 
      exists: false,
      error: error.message 
    });
  }
});

// Test subscription creation
router.post('/test-subscription', async (req, res) => {
  try {
    const { customerId, paymentMethodId } = req.body;
    console.log('Testing subscription creation with:', { customerId, paymentMethodId });
    
    // Test payment method
    const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);
    console.log('Payment method:', paymentMethod.id, paymentMethod.type);
    
    // Test customer
    const customer = await stripe.customers.retrieve(customerId);
    console.log('Customer:', customer.id, (customer as any).email);
    
    // Test subscription creation
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ price: 'price_1Rrm0vLUAmVQpcCRPCe9XF18' }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent'],
    });
    
    console.log('Subscription created:', subscription.id, subscription.status);
    
    res.json({
      success: true,
      subscription: {
        id: subscription.id,
        status: subscription.status,
        customerId: subscription.customer,
        items: subscription.items.data
      }
    });
  } catch (error: any) {
    console.error('Test subscription error:', error);
    res.status(400).json({ 
      success: false,
      error: error.message,
      type: error.type,
      code: error.code
    });
  }
});

export default router; 