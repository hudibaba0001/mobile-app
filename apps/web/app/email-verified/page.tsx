import Link from 'next/link'

export default function EmailVerifiedPage() {
  return (
    <div className="container">
      <div className="card message-page">
        <div className="success-icon" aria-hidden="true">✅</div>
        <h1 className="title">Email verified / E-post verifierad</h1>
        <p>
          Your email is verified. Open the KvikTime app and sign in.
          <br />
          Din e-post är verifierad. Öppna KvikTime-appen och logga in.
        </p>

        <a
          href="kviktime://login"
          className="button"
          style={{
            display: 'block',
            textAlign: 'center',
            textDecoration: 'none',
          }}
        >
          Open App / Öppna appen
        </a>

        <p style={{ marginTop: 12, marginBottom: 0, fontSize: 13 }}>
          If the app does not open automatically, open KvikTime manually and log in.
        </p>

        <Link href="/" className="link">
          Back to web
        </Link>
      </div>
    </div>
  )
}
