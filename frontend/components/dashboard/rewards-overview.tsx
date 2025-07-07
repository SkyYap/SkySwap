'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Gift, TrendingUp, Clock, DollarSign } from 'lucide-react';

const rewards = [
  {
    pool: 'ETH/USDC',
    earned: '$124.50',
    pending: '$15.20',
    apy: '24.5%',
    lastClaim: '2 days ago'
  },
  {
    pool: 'WBTC/ETH',
    earned: '$89.30',
    pending: '$8.90',
    apy: '18.7%',
    lastClaim: '1 day ago'
  },
  {
    pool: 'UNI/USDC',
    earned: '$45.80',
    pending: '$12.40',
    apy: '32.1%',
    lastClaim: '3 hours ago'
  }
];

export function RewardsOverview() {
  const totalEarned = rewards.reduce((sum, reward) => sum + parseFloat(reward.earned.replace('$', '')), 0);
  const totalPending = rewards.reduce((sum, reward) => sum + parseFloat(reward.pending.replace('$', '')), 0);

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-2">
              <DollarSign className="w-5 h-5 text-green-400" />
              <span className="text-gray-400">Total Earned</span>
            </div>
            <div className="text-2xl font-bold text-white">${totalEarned.toFixed(2)}</div>
          </CardContent>
        </Card>
        
        <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-2">
              <Clock className="w-5 h-5 text-blue-400" />
              <span className="text-gray-400">Pending Rewards</span>
            </div>
            <div className="text-2xl font-bold text-white">${totalPending.toFixed(2)}</div>
          </CardContent>
        </Card>
        
        <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-2">
              <TrendingUp className="w-5 h-5 text-purple-400" />
              <span className="text-gray-400">Avg APY</span>
            </div>
            <div className="text-2xl font-bold text-white">25.1%</div>
          </CardContent>
        </Card>
      </div>

      {/* Rewards Detail */}
      <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
        <CardHeader>
          <CardTitle className="flex items-center justify-between text-white">
            <div className="flex items-center gap-2">
              <Gift className="w-5 h-5" />
              Rewards by Pool
            </div>
            <Button className="bg-green-600 hover:bg-green-700">
              Claim All (${totalPending.toFixed(2)})
            </Button>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {rewards.map((reward, index) => (
              <motion.div
                key={reward.pool}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.3, delay: index * 0.1 }}
                className="flex items-center justify-between p-4 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm font-semibold">
                      {reward.pool.split('/')[0].slice(0, 1)}{reward.pool.split('/')[1].slice(0, 1)}
                    </span>
                  </div>
                  <div>
                    <div className="font-semibold text-white">{reward.pool}</div>
                    <div className="text-sm text-gray-400">Last claim: {reward.lastClaim}</div>
                  </div>
                </div>
                
                <div className="flex items-center gap-6">
                  <div className="text-right">
                    <div className="text-sm text-gray-400">Total Earned</div>
                    <div className="font-semibold text-white">{reward.earned}</div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm text-gray-400">Pending</div>
                    <div className="font-semibold text-green-400">{reward.pending}</div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm text-gray-400">APY</div>
                    <Badge variant="outline" className="text-green-400 border-green-400">
                      {reward.apy}
                    </Badge>
                  </div>
                  <Button size="sm" variant="outline">
                    Claim
                  </Button>
                </div>
              </motion.div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}