import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, ReferenceLine, LabelList,
  LineChart, Line, Legend,
} from 'recharts'

interface OutcomeRow {
  ethnicity: string
  outcome: string
  n: number
  total: number
  pct: number
}

interface NfaRow {
  financial_year: string
  ethnicity: string
  nfa_pct: number
}

interface ArrestPoint {
  ethnicity: string
  arrest: number
}

interface NfaTrendPoint {
  year: string
  Black: number
  White: number
  Asian: number
}

// Vertical lollipop: thin stem + circle at top
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const LollipopBar = (props: any) => {
  const { x, y, width, height, fill } = props
  if (!height || height <= 0) return null
  const cx = x + width / 2
  const r = 8
  return (
    <g>
      <line
        x1={cx} y1={y + r}
        x2={cx} y2={y + height}
        stroke={fill} strokeWidth={2.5} strokeLinecap="round"
      />
      <circle cx={cx} cy={y} r={r} fill={fill} />
    </g>
  )
}

// Custom reference line label — pill badge so it's always legible
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const WhiteBaselineLabel = ({ viewBox }: any) => {
  if (!viewBox) return null
  const { x, y, width } = viewBox
  const lx = x + width - 4
  const ly = y - 10
  const text = 'White baseline  13.3%'
  return (
    <g>
      <rect x={lx - 115} y={ly - 13} width={119} height={18} rx={5} fill="#F5F5F7" />
      <text x={lx - 56} y={ly} textAnchor="middle" fill="#6E6E73" fontSize={11}>
        {text}
      </text>
    </g>
  )
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const ArrestTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-xl bg-white/95 px-4 py-3 shadow-xl ring-1 ring-black/5 backdrop-blur">
      <p className="mb-1 text-xs font-semibold text-apple-dark">{label}</p>
      <p className="text-xs text-apple-grey">
        Arrest rate:{' '}
        <span className="font-semibold text-apple-dark">{payload[0].value.toFixed(1)}%</span>
      </p>
    </div>
  )
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const NfaTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-xl bg-white/95 px-4 py-3 shadow-xl ring-1 ring-black/5 backdrop-blur">
      <p className="mb-2 text-xs font-semibold text-apple-dark">{label}</p>
      {payload.map((p: { name: string; value: number; color: string }) => (
        <p key={p.name} className="text-xs" style={{ color: p.color }}>
          {p.name}: <span className="font-semibold">{p.value.toFixed(1)}%</span>
        </p>
      ))}
    </div>
  )
}

const NFA_COLOURS: Record<string, string> = {
  Black: '#1D1D1F',
  White: '#A1A1A6',
  Asian: '#6E6E73',
}

export default function OutcomeChart() {
  const [arrestData, setArrestData] = useState<ArrestPoint[]>([])
  const [trendData, setTrendData] = useState<NfaTrendPoint[]>([])

  useEffect(() => {
    fetch('/data/outcomes_by_ethnicity.json')
      .then(r => r.json())
      .then((rows: OutcomeRow[]) => {
        // White is shown as reference line only — exclude from data points
        const ethnicities = ['Black', 'Mixed', 'Other', 'Asian']
        const points: ArrestPoint[] = ethnicities.map(eth => ({
          ethnicity: eth,
          arrest: rows.find(r => r.ethnicity === eth && r.outcome === 'Arrest')?.pct ?? 0,
        }))
        points.sort((a, b) => b.arrest - a.arrest)
        setArrestData(points)
      })

    fetch('/data/nfa_by_year.json')
      .then(r => r.json())
      .then((rows: NfaRow[]) => {
        const years = [...new Set(rows.map(r => r.financial_year))].sort()
        const points: NfaTrendPoint[] = years.map(yr => {
          const sub = rows.filter(r => r.financial_year === yr)
          return {
            year: yr,
            Black: sub.find(r => r.ethnicity === 'Black')?.nfa_pct ?? 0,
            White: sub.find(r => r.ethnicity === 'White')?.nfa_pct ?? 0,
            Asian: sub.find(r => r.ethnicity === 'Asian')?.nfa_pct ?? 0,
          }
        })
        setTrendData(points)
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
            What Happens After a Stop?
          </h2>
          <p className="mt-4 max-w-2xl text-apple-grey">
            Black individuals have one of the{' '}
            <strong className="text-apple-dark">highest arrest rates</strong> of any ethnic
            group (16.0%, tied with Mixed) — 2.7 percentage points above White individuals
            (13.3%). Yet No Further Action rates are nearly identical across groups (~65–70%),
            meaning the disparity lies in who gets arrested, not in whether a search yields
            any outcome.
          </p>
        </motion.div>

        {/* Vertical lollipop — arrest rate vs White baseline */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="mt-12 h-72"
        >
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={arrestData}
              margin={{ top: 28, right: 24, left: 0, bottom: 8 }}
              barCategoryGap="45%"
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#F5F5F7" vertical={false} />
              <XAxis
                dataKey="ethnicity"
                tick={{ fontSize: 12, fill: '#6E6E73' }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                tick={{ fontSize: 12, fill: '#6E6E73' }}
                tickFormatter={v => `${v}%`}
                domain={[0, 20]}
                ticks={[0, 5, 10, 15, 20]}
                axisLine={false}
                tickLine={false}
              />
              <Tooltip content={<ArrestTooltip />} cursor={false} />
              <ReferenceLine
                y={13.3}
                stroke="#D2D2D7"
                strokeDasharray="4 4"
                label={<WhiteBaselineLabel />}
              />
              <Bar
                dataKey="arrest"
                shape={<LollipopBar fill="#1D1D1F" />}
                fill="#1D1D1F"
              >
                <LabelList
                  dataKey="arrest"
                  position="top"
                  offset={14}
                  formatter={(v: number) => `${v.toFixed(1)}%`}
                  style={{ fontSize: 11, fill: '#6E6E73' }}
                />
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </motion.div>
        <p className="mt-2 text-xs text-apple-grey">
          Arrest rate by ethnicity, all years combined (2020/21–2024/25). White shown as reference.
        </p>

        {/* NFA trend — line chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7, delay: 0.1 }}
          className="mt-20"
        >
          <h3 className="text-xl font-semibold tracking-tight text-apple-dark">
            No Further Action Rates Are Converging — But Remain High
          </h3>
          <p className="mt-2 max-w-2xl text-sm text-apple-grey">
            NFA rates by ethnicity across all five years. All groups see roughly 63–73% of
            searches result in no further action. The convergence over time shows this is a
            systemic problem — but Black individuals bear a disproportionate share of these
            intrusive encounters in absolute terms due to higher search volumes.
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
            <LineChart data={trendData} margin={{ top: 8, right: 24, left: 0, bottom: 8 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#F5F5F7" />
              <XAxis
                dataKey="year"
                tick={{ fontSize: 12, fill: '#6E6E73' }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                tick={{ fontSize: 12, fill: '#6E6E73' }}
                tickFormatter={v => `${v}%`}
                domain={[55, 80]}
                axisLine={false}
                tickLine={false}
              />
              <Tooltip content={<NfaTooltip />} />
              <Legend wrapperStyle={{ fontSize: 12, color: '#6E6E73', paddingTop: 16 }} />
              {Object.entries(NFA_COLOURS).map(([eth, colour]) => (
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
      </div>
    </section>
  )
}
