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
router.post('/create-account', async (req, res) => {
  try {
    const { email, password, name, phone, company, paymentMethodId } = req.body;

    // 1. Create Firebase Authentication user
    const userData: any = {
      email,
      password,
      displayName: name,
    };

    // Only add phone number if provided
    if (phone) userData.phoneNumber = phone;

    const userRecord = await admin.auth().createUser(userData);

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

    const customer = await stripe.customers.create(customerData);

    // 3. Attach payment method to customer
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customer.id,
    });

    // 4. Set as default payment method
    await stripe.customers.update(customer.id, {
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    });

    // 5. Create subscription
    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: 'price_1Rrm0vLUAmVQpcCRPCe9XF18' }], // Your 150 SEK price
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent'],
    });

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

    await admin.firestore().collection('users').doc(userRecord.uid).set(userProfile);

    res.json({
      success: true,
      userId: userRecord.uid,
      customerId: customer.id,
      subscriptionId: subscription.id,
      clientSecret: (subscription.latest_invoice as any)?.payment_intent?.client_secret,
    });
  } catch (error: any) {
    console.error('Account creation error:', error);
    res.status(400).json({ error: error.message });
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

export default router; 