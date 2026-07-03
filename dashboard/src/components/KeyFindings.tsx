import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'

interface KeyFindings {
  headline_ratio: number
  adjusted_irr: number
  male_irr: number
  nfa_rate_black: number
  total_searches_latest: number
  latest_year: string
}

const cardVariants = {
  hidden: { opacity: 0, y: 24 },
  visible: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, delay: i * 0.12, ease: [0.16, 1, 0.3, 1] },
  }),
}

export default function KeyFindings() {
  const [data, setData] = useState<KeyFindings | null>(null)

  useEffect(() => {
    fetch('/data/key_findings.json')
      .then(r => r.json())
      .then(setData)
  }, [])

  const cards = [
    {
      stat: data ? `${data.adjusted_irr}×` : '3.3×',
      label: 'Adjusted disparity rate for Black individuals',
      sub: `2024/25 — controlling for region, age, sex, and reason for search`,
    },
    {
      stat: data ? `${Math.round(data.nfa_rate_black)}%` : '69%',
      label: 'Of searches on Black individuals lead to no further action',
      sub: 'No arrest, no charge, no caution',
    },
    {
      stat: data ? `${data.male_irr}×` : '8×',
      label: 'More likely for males than females to be stopped',
      sub: 'The single strongest predictor in the model',
    },
    {
      stat: data ? `${(data.total_searches_latest / 1000).toFixed(0)}K` : '403K',
      label: `Stop and searches in ${data?.latest_year ?? '2024/25'}`,
      sub: 'Excluding vehicle searches and BTP',
    },
  ]

  return (
    <section className="bg-apple-light px-6 py-32">
      <div className="mx-auto max-w-5xl">
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7 }}
          className="text-center text-3xl font-semibold tracking-tight text-apple-dark sm:text-4xl"
        >
          Key Findings
        </motion.h2>
        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7, delay: 0.1 }}
          className="mx-auto mt-4 max-w-xl text-center text-apple-grey"
        >
          Five years of data (2020/21&ndash;2024/25), modelled using a Quasi-Poisson
          regression with population offsets.
        </motion.p>

        <div className="mt-16 grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          {cards.map((card, i) => (
            <motion.div
              key={card.label}
              custom={i}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true }}
              variants={cardVariants}
              className="flex flex-col items-center text-center"
            >
              <p className="text-5xl font-bold tracking-tight text-apple-dark">
                {card.stat}
              </p>
              <p className="mt-3 text-sm font-medium text-apple-dark">{card.label}</p>
              <p className="mt-1 text-xs text-apple-grey">{card.sub}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
