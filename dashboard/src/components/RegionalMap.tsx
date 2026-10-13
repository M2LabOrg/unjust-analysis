import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Cell
} from 'recharts'

interface RegionalRow {
  region_clean: string
  rate_Asian: number
  rate_Black: number
  rate_Mixed: number
  rate_Other: number
  rate_White: number
  black_white_ratio: number
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null
  const d = payload[0].payload as RegionalRow
  return (
    <div className="rounded-xl bg-white/95 px-4 py-3 shadow-xl ring-1 ring-black/5">
      <p className="mb-2 text-xs font-semibold text-apple-dark">{label}</p>
      <p className="text-xs text-apple-dark">
        Black: <span className="font-semibold">{d.rate_Black.toFixed(1)}</span> per 1,000
      </p>
      <p className="text-xs text-apple-grey">
        White: <span className="font-semibold">{d.rate_White.toFixed(1)}</span> per 1,000
      </p>
      <p className="mt-1 text-xs font-semibold text-apple-dark">
        Ratio: {d.black_white_ratio}×
      </p>
    </div>
  )
}

export default function RegionalMap() {
  const [data, setData] = useState<RegionalRow[]>([])
  const [metric, setMetric] = useState<'ratio' | 'rate'>('ratio')

  useEffect(() => {
    fetch('/data/regional_disparity.json')
      .then(r => r.json())
      .then((rows: RegionalRow[]) => {
        const sorted = [...rows].sort((a, b) => b.black_white_ratio - a.black_white_ratio)
        setData(sorted)
      })
  }, [])

  const chartData = data.map(d => ({
    ...d,
    name: d.region_clean.replace('Yorkshire and The Humber', 'Yorkshire'),
    value: metric === 'ratio' ? d.black_white_ratio : d.rate_Black,
  }))

  const maxVal = Math.max(...chartData.map(d => d.value))

  return (
    <section className="bg-apple-light px-6 py-32">
      <div className="mx-auto max-w-5xl">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7 }}
        >
          <h2 className="text-3xl font-semibold tracking-tight text-apple-dark sm:text-4xl">
            Where Is It Worst?
          </h2>
          <p className="mt-4 max-w-2xl text-apple-grey">
            Regional breakdown for 2024/25. The South West has the highest
            Black:White ratio (5.1×) — Black individuals there are five times
            more likely to be stopped than White individuals in the same region.
          </p>
        </motion.div>

        {/* Toggle */}
        <div className="mt-10 flex gap-3">
          {(['ratio', 'rate'] as const).map(m => (
            <button
              key={m}
              onClick={() => setMetric(m)}
              className={`rounded-full px-3 py-1.5 text-xs font-medium whitespace-nowrap transition-all ${
                metric === m
                  ? 'bg-apple-dark text-white'
                  : 'bg-white text-apple-grey hover:text-apple-dark'
              }`}
            >
              {m === 'ratio' ? 'Black:White ratio' : 'Rate per 1,000 (Black)'}
            </button>
          ))}
        </div>

        <motion.div
          key={metric}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.4 }}
          className="mt-8 h-80"
        >
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              layout="vertical"
              data={chartData}
              margin={{ top: 4, right: 40, left: 10, bottom: 4 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#E8E8ED" horizontal={false} />
              <XAxis
                type="number"
                tick={{ fontSize: 11, fill: '#6E6E73' }}
                tickFormatter={v => metric === 'ratio' ? `${v}×` : v.toFixed(1)}
                domain={[0, Math.ceil(maxVal * 1.1)]}
              />
              <YAxis
                type="category"
                dataKey="name"
                tick={{ fontSize: 11, fill: '#6E6E73' }}
                width={130}
              />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: '#F5F5F7' }} />
              <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                {chartData.map((entry, i) => (
                  <Cell
                    key={entry.region_clean}
                    fill={i === 0 ? '#1D1D1F' : i < 3 ? '#6E6E73' : '#D2D2D7'}
                  />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </motion.div>

        <p className="mt-4 text-xs text-apple-grey">
          Source: Home Office open data tables, year ending March 2025. Population
          denominator: ONS Census 2021. BTP and vehicle searches excluded.
        </p>
      </div>
    </section>
  )
}
