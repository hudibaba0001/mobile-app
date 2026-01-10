export default function TermsPage() {
  return (
    <div className="container">
      <div className="card">
        <h1 className="title">Terms of Service</h1>
        <div style={{ textAlign: 'left', color: '#333', lineHeight: 1.6 }}>
          <p>
            <strong>Last updated: January 2026</strong>
          </p>
          <p>
            These Terms of Service govern your use of the Time Tracker
            application and services.
          </p>
          <h2 style={{ fontSize: '18px', marginTop: '24px' }}>1. Acceptance of Terms</h2>
          <p>
            By accessing or using our service, you agree to be bound by these
            terms.
          </p>
          <h2 style={{ fontSize: '18px', marginTop: '24px' }}>2. Subscription</h2>
          <p>
            The service is provided on a subscription basis. You will be charged
            the applicable subscription fee after your free trial period ends.
          </p>
          <h2 style={{ fontSize: '18px', marginTop: '24px' }}>3. Free Trial</h2>
          <p>
            New users receive a 7-day free trial. You may cancel at any time
            before the trial ends to avoid charges.
          </p>
          <p style={{ marginTop: '24px', fontSize: '14px', color: '#666' }}>
            This is a placeholder. Replace with your actual terms.
          </p>
        </div>
        <a href="/signup" className="link" style={{ marginTop: '24px' }}>
          Back to Sign Up
        </a>
      </div>
    </div>
  )
}
