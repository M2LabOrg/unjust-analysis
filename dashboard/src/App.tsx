import Hero from './components/Hero'
import KeyFindings from './components/KeyFindings'
import TrendChart from './components/TrendChart'
import RegionalMap from './components/RegionalMap'
import OutcomeChart from './components/OutcomeChart'
import NewInsights from './components/NewInsights'
import Methodology from './components/Methodology'
import Footer from './components/Footer'

function App() {
  return (
    <main className="font-sans antialiased">
      <Hero />
      <KeyFindings />
      <TrendChart />
      <RegionalMap />
      <OutcomeChart />
      <NewInsights />
      <Methodology />
      <Footer />
    </main>
  )
}

export default App
