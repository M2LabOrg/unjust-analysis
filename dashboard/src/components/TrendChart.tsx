import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  Legend, ResponsiveContainer, ReferenceLine
} from 'recharts'

interface DisparityRow {
  financial_year: string
  ethnicity: string
  rate_per_1000: number
  ratio_vs_white: number
}

interface YearPoint {
  year: string
  Black: number
  Asian: number
  Mixed: number
  Other: number
}

interface IrrRow {
  financial_year: string
  ethnicity: string
  irr: number
  irr_lower: number
  irr_upper: number
}

interface IrrPoint {
  year: string
  irr: number
  lower: number
  upper: number
}

const ETHNICITY_COLOURS: Record<string, string> = {
  Black: '#1D1D1F',
  Asian: '#6E6E73',
  Mixed: '#A1A1A6',
  Other: '#D2D2D7',
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-xl bg-white/95 px-4 py-3 shadow-xl ring-1 ring-black/5 backdrop-blur">
      <p className="mb-2 text-xs font-semibold text-apple-dark">{label}</p>
      {payload.map((p: { name: string; value: number; color: string }) => (
        <p key={p.name} className="text-xs" style={{ color: p.color }}>
          {p.name}: <span className="font-semibold">{p.value.toFixed(2)}×</span>
        </p>
      ))}
    </div>
  )
}

export default function TrendChart() {
  const [rawData, setRawData] = useState<YearPoint[]>([])
  const [irrData, setIrrData] = useState<IrrPoint[]>([])

  useEffect(() => {
    fetch('/data/disparity_trend.json')
      .then(r => r.json())
      .then((rows: DisparityRow[]) => {
        const years = [...new Set(rows.map(r => r.financial_year))].sort()
        const points: YearPoint[] = years.map(yr => {
          const yr_rows = rows.filter(r => r.financial_year === yr)
          return {
            year: yr,
            Black: yr_rows.find(r => r.ethnicity === 'Black')?.ratio_vs_white ?? 0,
            Asian: yr_rows.find(r => r.ethnicity === 'Asian')?.ratio_vs_white ?? 0,
            Mixed: yr_rows.find(r => r.ethnicity === 'Mixed')?.ratio_vs_white ?? 0,
            Other: yr_rows.find(r => r.ethnicity === 'Other')?.ratio_vs_white ?? 0,
          }
        })
        setRawData(points)
      })

    fetch('/data/yearly_irr.json')
      .then(r => r.json())
      .then((rows: IrrRow[]) => {
        const blackRows = rows
          .filter(r => r.ethnicity === 'Black')
          .sort((a, b) => a.financial_year.localeCompare(b.financial_year))
        setIrrData(blackRows.map(r => ({
          year: r.financial_year,
          irr: r.irr,
          lower: r.irr_lower,
          upper: r.irr_upper,
        })))
      })
  }, [])

  return (
    <section className="bg-white px-6 py-32">
      <div className="mx-auto max-w-5xl">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7 }}
        >
          <h2 className="text-3xl font-semibold tracking-tight text-apple-dark sm:text-4xl">
            Is It Getting Better?
          </h2>
          <p className="mt-4 max-w-2xl text-apple-grey">
            Raw disparity ratios (stops per 1,000 population relative to White individuals)
            across five financial years. The gap for Black individuals widened in 2024/25
            after narrowing in 2022/23.
          </p>
        </motion.div>

        {/* Raw ratio chart */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="mt-12 h-80"
        >
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={rawData} margin={{ top: 8, right: 24, left: 0, bottom: 8 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#F5F5F7" />
              <XAxis dataKey="year" tick={{ fontSize: 12, fill: '#6E6E73' }} />
              <YAxis
                tick={{ fontSize: 12, fill: '#6E6E73' }}
                tickFormatter={v => `${v}×`}
                domain={[0, 'auto']}
              />
              <Tooltip content={<CustomTooltip />} />
              <Legend
                wrapperStyle={{ fontSize: 12, color: '#6E6E73', paddingTop: 16 }}
              />
              <ReferenceLine y={1} stroke="#D2D2D7" strokeDasharray="4 4" label={{ value: 'White baseline', fill: '#A1A1A6', fontSize: 11 }} />
              {Object.entries(ETHNICITY_COLOURS).map(([eth, colour]) => (
                <Line
                  key={eth}
                  type="monotone"
                  dataKey={eth}
                  stroke={colour}
                  strokeWidth={eth === 'Black' ? 2.5 : 1.5}
                  dot={{ r: eth === 'Black' ? 4 : 3, fill: colour }}
                  activeDot={{ r: 6 }}
                />
              ))}
            </LineChart>
          </ResponsiveContainer>
        </motion.div>

        {/* Adjusted IRR for Black */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7, delay: 0.1 }}
          className="mt-20"
        >
          <h3 className="text-xl font-semibold tracking-tight text-apple-dark">
            Adjusted Rate for Black Individuals
          </h3>
          <p className="mt-2 max-w-2xl text-sm text-apple-grey">
            Incidence Rate Ratio from the Quasi-Poisson model — controlling for region,
            sex, age, and reason. This is the disparity <em>after</em> accounting for
            differences in who is being searched and where. The ratio rose from 3.0×
            in 2020/21 to 3.3× in 2024/25.
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="mt-8 h-64"
        >
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={irrData} margin={{ top: 8, right: 24, left: 0, bottom: 8 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#F5F5F7" />
              <XAxis dataKey="year" tick={{ fontSize: 12, fill: '#6E6E73' }} />
              <YAxis
                tick={{ fontSize: 12, fill: '#6E6E73' }}
                tickFormatter={v => `${v}×`}
                domain={[2, 4]}
              />
              <Tooltip
                formatter={(v: number) => [`${v.toFixed(2)}×`, 'Adjusted IRR']}
                contentStyle={{ borderRadius: 12, fontSize: 12 }}
              />
              <ReferenceLine y={1} stroke="#D2D2D7" strokeDasharray="4 4" />
              <Line
                type="monotone"
                dataKey="irr"
                stroke="#1D1D1F"
                strokeWidth={2.5}
                dot={{ r: 5, fill: '#1D1D1F' }}
                activeDot={{ r: 7 }}
                name="Adjusted IRR (Black vs White)"
              />
              {/* CI band approximation using upper/lower as separate lines */}
              <Line type="monotone" dataKey="upper" stroke="#D2D2D7" strokeWidth={1} dot={false} strokeDasharray="3 3" name="95% CI upper" />
              <Line type="monotone" dataKey="lower" stroke="#D2D2D7" strokeWidth={1} dot={false} strokeDasharray="3 3" name="95% CI lower" />
            </LineChart>
          </ResponsiveContainer>
        </motion.div>

        <p className="mt-4 text-xs text-apple-grey">
          Dashed lines show 95% confidence intervals. Reference group: White female,
          age 25+, non-drug search.
        </p>
      </div>
    </section>
  )
}
