import { motion, useInView } from 'framer-motion'
import { useEffect, useRef, useState } from 'react'

interface InsightProps {
  number: string
  title: string
  body: string
  source?: string
  accent?: boolean
}

interface InsightsData {
  latest_year: string
  first_year: string
  finding_01: { raw_ratio_first: number; raw_ratio_latest: number; irr_first: number; irr_latest: number }
  finding_02: { pct_under25_black: number; pct_under25_white: number; male_irr: number }
  finding_03: { worst_region: string; black_white_ratio: number; black_pop_pct: number }
  finding_04: { nfa_pct_black: number; nfa_pct_white: number; raw_ratio: number }
  finding_05: { drug_pct_black: number; drug_pct_white: number }
  finding_06: { overall_missing_pct: number; worst_forces: { police_force: string; pct_missing: number }[] }
}

function Insight({ number, title, body, source, accent = false }: InsightProps) {
  const ref = useRef(null)
  const inView = useInView(ref, { once: true, margin: '-80px' })

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, x: -20 }}
      animate={inView ? { opacity: 1, x: 0 } : {}}
      transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
      className={`border-l-2 pl-8 py-2 ${accent ? 'border-apple-dark' : 'border-apple-mist'}`}
    >
      <p className="text-xs font-semibold uppercase tracking-widest text-apple-grey mb-3">
        Finding {number}
      </p>
      <p className={`text-4xl font-bold tracking-tight mb-4 ${accent ? 'text-apple-dark' : 'text-apple-dark'}`}>
        {title}
      </p>
      <p className="max-w-xl text-apple-grey leading-relaxed">
        {body}
      </p>
      {source && (
        <p className="mt-3 text-xs text-apple-silver">{source}</p>
      )}
    </motion.div>
  )
}

export default function NewInsights() {
  const [d, setD] = useState<InsightsData | null>(null)

  useEffect(() => {
    fetch('/data/insights.json')
      .then(r => r.json())
      .then(setD)
  }, [])

  const f01 = d?.finding_01
  const f02 = d?.finding_02
  const f03 = d?.finding_03
  const f04 = d?.finding_04
  const f05 = d?.finding_05
  const f06 = d?.finding_06

  const worstForcesText = f06
    ? f06.worst_forces.map(f => `${f.police_force} (${f.pct_missing}% missing)`).join(', ')
    : 'London, City of (43% missing), Nottinghamshire (40%), North Wales (34%), and Metropolitan Police (31%)'

  return (
    <section className="bg-apple-light px-6 py-32">
      <div className="mx-auto max-w-5xl">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7 }}
          className="mb-20"
        >
          <h2 className="text-3xl font-semibold tracking-tight text-apple-dark sm:text-4xl">
            Beyond the Headlines
          </h2>
          <p className="mt-4 max-w-2xl text-apple-grey">
            Five years of data reveal patterns that annual snapshots cannot.
          </p>
        </motion.div>

        <div className="flex flex-col gap-16">
          <Insight
            number="01"
            title="The raw gap narrowed, but the structural disparity widened."
            body={`The unadjusted rate ratio for Black individuals fell from ${f01?.raw_ratio_first ?? '…'}× in ${d?.first_year ?? '…'} to ${f01?.raw_ratio_latest ?? '…'}× in ${d?.latest_year ?? '…'}, largely driven by a post-pandemic drop in overall search volumes. However, after controlling for region, sex, age, and reason for search, the adjusted disparity actually rose from ${f01?.irr_first ?? '…'}× to ${f01?.irr_latest ?? '…'}× over the same period. This means the underlying structural inequality — the part not explained by demographic or geographic factors — has grown, even as headline figures appear to improve.`}
            source={`Quasi-Poisson model, per-year IRR. Reference group: White female, age 25+, non-drug search.`}
            accent
          />

          <Insight
            number="02"
            title="Young Black men face a compounding disadvantage."
            body={`${f02?.pct_under25_black ?? '…'}% of all stop and searches on Black individuals target those under 25, compared to ${f02?.pct_under25_white ?? '…'}% for White individuals. Males are ${f02?.male_irr ?? '…'}× more likely to be stopped than females. For a young Black male, these effects multiply — placing this group as the most disproportionately targeted demographic by a significant margin.`}
            source={`Age and sex breakdown from stop-and-search open data, ${d?.latest_year ?? '2024/25'}.`}
          />

          <Insight
            number="03"
            title={`The ${f03?.worst_region ?? 'South West'} has the worst disparity ratio.`}
            body={`Black individuals in the ${f03?.worst_region ?? 'South West'} are stopped at ${f03?.black_white_ratio ?? '…'}× the rate of White individuals — the highest regional ratio in England and Wales. This is striking given the ${f03?.worst_region ?? 'South West'} has the smallest Black population of any English region (just over ${f03?.black_pop_pct ?? '…'}% of the regional population), yet the disparity is the most severe.`}
            source={`Population-adjusted rates by region, ${d?.latest_year ?? '2024/25'}. ONS Census 2021 denominator.`}
          />

          <Insight
            number="04"
            title={`${f04?.nfa_pct_black ?? 69}% of searches on Black individuals find nothing.`}
            body={`No Further Action — the outcome where a person is stopped, searched, and released without arrest, caution, or charge — is recorded for ${f04?.nfa_pct_black ?? '…'}% of searches on Black individuals and ${f04?.nfa_pct_white ?? '…'}% of searches on White individuals. The rates are nearly identical, yet Black individuals are searched at ${f04?.raw_ratio ?? '…'}× the rate. In practice, this means thousands more Black individuals each year experience an intrusive police encounter that leads to no action — the same outcome rate applied to a far larger volume of searches.`}
            source="Outcome breakdown from stop-and-search data, all years combined."
          />

          <Insight
            number="05"
            title="Drug searches drive the disparity more than weapons searches."
            body={`In ${d?.latest_year ?? '2024/25'}, ${f05?.drug_pct_black ?? '…'}% of searches on Black individuals were drug-related, compared to ${f05?.drug_pct_white ?? '…'}% for White individuals — a narrowing gap over time. However, because total search volumes are so much higher for Black individuals, drug searches remain a primary mechanism through which racial disparity is expressed in policing practice.`}
            source={`Reason for search breakdown, ${d?.first_year ?? '2020/21'} to ${d?.latest_year ?? '2024/25'}.`}
          />

          <Insight
            number="06"
            title="Data quality is uneven — and that matters."
            body={`In ${d?.latest_year ?? '2024/25'}, ${f06?.overall_missing_pct ?? '…'}% of all stop-and-search records have missing self-defined ethnicity data. Some forces are far worse: ${worstForcesText}. Self-defined ethnicity is voluntary — individuals are not required to state it during a stop. When ethnicity is unrecorded, these stops cannot be included in disparity calculations, which means force-level estimates are based on a partial record and should be interpreted with caution.`}
            source={`Missing ethnicity analysis by force, ${d?.latest_year ?? '2024/25'}.`}
          />
        </div>
      </div>
    </section>
  )
}
