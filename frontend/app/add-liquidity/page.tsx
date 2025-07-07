'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { LiquidityInterface } from '@/components/liquidity/liquidity-interface';
import { LiquidityChart } from '@/components/liquidity/liquidity-chart';
import { Shield } from 'lucide-react';

const pools = [
  { pair: 'ETH/USSKY', apy: '24.5%', tvl: '$12.4M', ilProtected: true },
  { pair: 'BTC/USSKY', apy: '18.7%', tvl: '$8.9M', ilProtected: true },
  { pair: 'UNI/USSKY', apy: '32.1%', tvl: '$4.2M', ilProtected: false },
  { pair: 'LINK/USSKY', apy: '28.9%', tvl: '$3.8M', ilProtected: true },
  { pair: 'AAVE/USSKY', apy: '41.2%', tvl: '$2.1M', ilProtected: false },
];

export default function AddLiquidity() {
  const [selectedPool, setSelectedPool] = useState('ETH/USSKY');
  const currentPool = pools.find(p => p.pair === selectedPool) || pools[0];
  const expectedAPY = currentPool?.apy || '24.5%';
  const poolShare = '0.12%';
  const expectedFees = '$15.20/day';
  const enableHedging = false; // Not available at this level

  return (
    <div className="container mx-auto px-4 py-8">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="mb-8"
      >
        <h1 className="text-3xl font-bold text-white mb-2">Add Liquidity</h1>
        <p className="text-gray-400">Provide liquidity and earn fees without impermanent loss</p>
      </motion.div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
        <div className="md:col-span-2">
          <LiquidityChart 
            selectedPool={selectedPool} 
            onPoolChange={setSelectedPool}
          />
        </div>
        {/* Pool Information Section */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex justify-center items-center h-full"
        >
          <div className="w-full max-w-sm p-4 bg-white/5 rounded-lg space-y-3">
            <h3 className="text-white font-medium">{currentPool.pair} Pool Info</h3>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-400">APY</span>
                <span className="text-green-400 font-medium">{currentPool.apy}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">TVL</span>
                <span className="text-white">{currentPool.tvl}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Pool Share</span>
                <span className="text-white">{poolShare}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Expected Fees</span>
                <span className="text-white">{expectedFees}</span>
              </div>
            </div>
            {enableHedging && (
              <div className="flex justify-between text-sm pt-2 border-t border-white/10">
                <div className="flex items-center gap-1">
                  <Shield className="w-3 h-3 text-green-400" />
                  <span className="text-gray-400">IL Risk</span>
                </div>
                <span className="text-green-400">Protected</span>
              </div>
            )}
          </div>
        </motion.div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
      >
        <LiquidityInterface selectedPool={selectedPool} />
      </motion.div>
    </div>
  );
}