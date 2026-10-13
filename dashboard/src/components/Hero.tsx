import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'

interface KeyFindings {
  headline_ratio: number
  adjusted_irr: number
  male_irr: number
  nfa_rate_black: number
  total_searches_latest: number
  latest_year: string
  data_years: string
}

export default function Hero() {
  const [data, setData] = useState<KeyFindings | null>(null)

  useEffect(() => {
    fetch('/data/key_findings.json')
      .then(r => r.json())
      .then(setData)
  }, [])

  const ratio = data?.headline_ratio ?? 3.6

  return (
    <section className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-apple-dark px-6 text-center text-white">
      {/* Subtle background gradient */}
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-black/20 via-transparent to-black/40" />

      <motion.div
        initial={{ opacity: 0, y: 32 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
        className="relative z-10 max-w-4xl"
      >
        {/* Eyebrow */}
        <p className="mb-6 text-sm font-medium tracking-widest text-apple-silver uppercase">
          England &amp; Wales &mdash; {data?.data_years ?? '2020/21 to 2024/25'}
        </p>

        {/* Title */}
        <h1 className="text-5xl font-semibold leading-tight tracking-tight sm:text-7xl">
          Stop and Search in{' '}
          <span className="text-apple-blue">Black Communities</span>
        </h1>

        <p className="mx-auto mt-6 max-w-2xl text-lg text-apple-silver sm:text-xl">
          A statistical analysis of police stop-and-search practices across five years
          of official data.
        </p>
      </motion.div>

      {/* Big number */}
      <motion.div
        initial={{ opacity: 0, scale: 0.85 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 1, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
        className="relative z-10 mt-20 text-center"
      >
        <p className="text-[9rem] font-bold leading-none tracking-tight text-white sm:text-[12rem]">
          {ratio}×
        </p>
        <p className="mt-3 text-base text-apple-silver sm:text-lg">
          Black individuals are stopped at{' '}
          <span className="text-white font-medium">{ratio} times</span> the rate
          of White individuals in {data?.latest_year ?? '2024/25'}.
        </p>
      </motion.div>

      {/* Scroll cue */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2, duration: 0.6 }}
        className="relative z-10 mt-24 flex flex-col items-center gap-2 text-apple-silver"
      >
        <span className="text-xs tracking-widest uppercase">Scroll to explore</span>
        <motion.div
          animate={{ y: [0, 6, 0] }}
          transition={{ repeat: Infinity, duration: 1.6, ease: 'easeInOut' }}
        >
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 9l-7 7-7-7" />
          </svg>
        </motion.div>
      </motion.div>
    </section>
  )
}
