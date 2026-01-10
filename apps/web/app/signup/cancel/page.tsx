import Link from 'next/link'

export default function SignupCancelPage() {
  return (
    <div className="container">
      <div className="card message-page">
        <div className="success-icon">⚠️</div>
        <h1 className="title">Payment Required</h1>
        <p>
          Payment is required to activate your 7-day free trial. Your card will
          not be charged until the trial ends.
        </p>
        <Link
          href="/signup"
          className="button"
          style={{ display: 'block', textAlign: 'center', textDecoration: 'none' }}
        >
          Try Again
        </Link>
      </div>
    </div>
  )
}
