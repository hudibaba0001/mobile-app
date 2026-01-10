import Link from 'next/link'

export default function SignupSuccessPage() {
  return (
    <div className="container">
      <div className="card message-page">
        <div className="success-icon">✅</div>
        <h1 className="title">Payment Started!</h1>
        <p>
          Your 7-day free trial has begun. Open the app and log in with your
          email and password to get started.
        </p>
        <a
          href="/"
          className="button"
          style={{ display: 'block', textAlign: 'center', textDecoration: 'none' }}
        >
          Open App
        </a>
        <p style={{ marginTop: '24px', fontSize: '13px', color: '#888' }}>
          You can also download the app from the App Store or Google Play.
        </p>
      </div>
    </div>
  )
}
