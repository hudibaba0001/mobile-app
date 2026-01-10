export default function PrivacyPage() {
  return (
    <div className="container">
      <div className="card">
        <h1 className="title">Privacy Policy</h1>
        <div style={{ textAlign: 'left', color: '#333', lineHeight: 1.6 }}>
          <p>
            <strong>Last updated: January 2026</strong>
          </p>
          <p>
            This Privacy Policy describes how we collect, use, and protect your
            personal information.
          </p>
          <h2 style={{ fontSize: '18px', marginTop: '24px' }}>1. Information We Collect</h2>
          <p>
            We collect information you provide directly, such as your email
            address and work time entries.
          </p>
          <h2 style={{ fontSize: '18px', marginTop: '24px' }}>2. How We Use Your Information</h2>
          <p>
            We use your information to provide and improve our services, process
            payments, and communicate with you.
          </p>
          <h2 style={{ fontSize: '18px', marginTop: '24px' }}>3. Data Security</h2>
          <p>
            We implement appropriate security measures to protect your personal
            information.
          </p>
          <p style={{ marginTop: '24px', fontSize: '14px', color: '#666' }}>
            This is a placeholder. Replace with your actual privacy policy.
          </p>
        </div>
        <a href="/signup" className="link" style={{ marginTop: '24px' }}>
          Back to Sign Up
        </a>
      </div>
    </div>
  )
}
