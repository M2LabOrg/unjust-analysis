export default function Footer() {
  return (
    <footer className="border-t border-apple-mist px-6 py-16">
      <div className="mx-auto max-w-5xl text-center text-sm text-apple-grey">
        <p>
          A project by{' '}
          <a href="https://m2lab.io" className="underline hover:text-apple-dark">
            Michel Mesquita, Ph.D., CStat
          </a>{' '}
          for{' '}
          <a href="https://www.theunjustproject.com/" className="underline hover:text-apple-dark">
            UNJUST
          </a>
        </p>
        <p className="mt-2">
          Royal Statistical Society &mdash; Statisticians for Society
        </p>
        <div className="mt-6 flex justify-center gap-6">
          <a href="/report/" className="underline hover:text-apple-dark">
            Full Report
          </a>
          <a href="https://github.com/M2LabOrg/unjust-analysis" className="underline hover:text-apple-dark">
            GitHub
          </a>
        </div>
        <p className="mt-8 text-apple-silver">
          Data: Home Office, ONS Census 2021. Apache 2.0 License.
        </p>
      </div>
    </footer>
  )
}
