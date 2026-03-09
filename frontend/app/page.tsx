import Image from "next/image";

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background text-foreground font-sans">
      <header className="fixed top-0 left-0 right-0 p-6 flex justify-between items-center max-w-7xl mx-auto w-full">
        <div className="text-2xl font-bold text-primary flex items-center gap-2">
          <div className="w-8 h-8 bg-primary rounded-lg"></div>
          SmartX
        </div>
        <button className="px-6 py-2 bg-primary text-primary-foreground rounded-full font-medium hover:opacity-90 transition-opacity">
          Launch App
        </button>
      </header>

      <main className="flex flex-col items-center justify-center px-6 text-center max-w-4xl">
        <h1 className="text-5xl sm:text-7xl font-bold tracking-tight mb-6">
          Intelligence meets <span className="text-primary">Yield</span>
        </h1>
        <p className="text-xl text-gray-600 dark:text-gray-400 mb-10 max-w-2xl">
          Create personalized ERC-4626 vaults, automate your DeFi strategies, and maximize your returns on Base.
        </p>
        
        <div className="flex flex-col sm:flex-row gap-4">
          <button className="px-8 py-4 bg-primary text-primary-foreground rounded-xl font-bold text-lg hover:shadow-lg hover:shadow-primary/20 transition-all">
            Get Started
          </button>
          <button className="px-8 py-4 bg-secondary text-secondary-foreground rounded-xl font-bold text-lg hover:shadow-lg hover:shadow-secondary/20 transition-all">
            View Strategies
          </button>
        </div>
      </main>

      <footer className="fixed bottom-0 left-0 right-0 p-8 text-center text-gray-500 text-sm">
        &copy; 2026 SmartX Protocol. Built on Base.
      </footer>
    </div>
  );
}
