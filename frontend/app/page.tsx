'use client';

import { motion } from 'framer-motion';
import Link from 'next/link';
import { ArrowRight, TrendingUp, Shield, Zap, Users } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

const features = [
  {
    icon: TrendingUp,
    title: 'Advanced Trading',
    description: 'Swap tokens with minimal slippage and optimal routing across multiple DEXs.'
  },
  {
    icon: Shield,
    title: 'IL-Proof Liquidity',
    description: 'Provide liquidity without impermanent loss risk through advanced hedging mechanisms.'
  },
  {
    icon: Zap,
    title: 'Automated Strategies',
    description: 'Set up automated position management and risk mitigation strategies.'
  },
  {
    icon: Users,
    title: 'Community Driven',
    description: 'Join a community of DeFi enthusiasts and professional traders.'
  }
];

export default function Home() {
  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="relative px-4 py-20 text-center">
        <div className="container mx-auto max-w-4xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="space-y-6"
          >
            <h1 className="text-5xl md:text-6xl font-bold bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
              The Future of DeFi Trading
            </h1>
            <p className="text-xl md:text-2xl text-gray-300 max-w-2xl mx-auto">
              Trade, provide liquidity, and earn yields on the most advanced AMM platform with zero impermanent loss.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center pt-8">
              <Button asChild size="lg" className="bg-blue-600 hover:bg-blue-700 text-lg px-8">
                <Link href="/swap">
                  Start Trading
                  <ArrowRight className="ml-2 w-5 h-5" />
                </Link>
              </Button>
              <Button asChild variant="outline" size="lg" className="text-lg px-8">
                <Link href="/add-liquidity">
                  Provide Liquidity
                </Link>
              </Button>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section className="px-4 py-20">
        <div className="container mx-auto max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Why Choose SkySwap?
            </h2>
            <p className="text-gray-400 text-lg max-w-2xl mx-auto">
              Built for traders who demand the best. Our platform combines cutting-edge technology with user-friendly design.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((feature, index) => (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, delay: 0.3 + index * 0.1 }}
              >
                <Card className="bg-black/20 border-white/10 hover:bg-black/30 transition-all duration-300">
                  <CardContent className="p-6 text-center">
                    <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center mx-auto mb-4">
                      <feature.icon className="w-6 h-6 text-white" />
                    </div>
                    <h3 className="text-xl font-semibold text-white mb-2">
                      {feature.title}
                    </h3>
                    <p className="text-gray-400">
                      {feature.description}
                    </p>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="px-4 py-20 bg-black/20">
        <div className="container mx-auto max-w-4xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center"
          >
            <div>
              <div className="text-3xl md:text-4xl font-bold text-blue-400 mb-2">
                $2.4B+
              </div>
              <div className="text-gray-400">Total Value Locked</div>
            </div>
            <div>
              <div className="text-3xl md:text-4xl font-bold text-purple-400 mb-2">
                150K+
              </div>
              <div className="text-gray-400">Active Users</div>
            </div>
            <div>
              <div className="text-3xl md:text-4xl font-bold text-pink-400 mb-2">
                99.9%
              </div>
              <div className="text-gray-400">Uptime</div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  );
}