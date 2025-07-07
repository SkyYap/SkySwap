'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Info, TrendingUp, Users, DollarSign } from 'lucide-react';

const pools = [
  {
    pair: 'ETH/USDC',
    tvl: '$12.4M',
    apy: '24.5%',
    volume24h: '$1.9M',
    fees24h: '$5,700',
    participants: 847,
    myShare: 0.12,
    status: 'Active'
  },
  {
    pair: 'WBTC/ETH',
    tvl: '$8.9M',
    apy: '18.7%',
    volume24h: '$1.2M',
    fees24h: '$3,600',
    participants: 623,
    myShare: 0.08,
    status: 'Active'
  },
  {
    pair: 'UNI/USDC',
    tvl: '$4.2M',
    apy: '32.1%',
    volume24h: '$800K',
    fees24h: '$2,400',
    participants: 412,
    myShare: 0.05,
    status: 'New'
  },
];

export function PoolInformation() {
  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-white">
          <Info className="w-5 h-5" />
          Pool Information
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {pools.map((pool, index) => (
            <motion.div
              key={pool.pair}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: index * 0.1 }}
              className="p-4 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm font-semibold">
                      {pool.pair.split('/')[0].slice(0, 1)}{pool.pair.split('/')[1].slice(0, 1)}
                    </span>
                  </div>
                  <div>
                    <div className="font-semibold text-white">{pool.pair}</div>
                    <Badge variant={pool.status === 'New' ? 'default' : 'outline'} className="text-xs">
                      {pool.status}
                    </Badge>
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-semibold text-white">{pool.tvl}</div>
                  <div className="text-sm text-gray-400">TVL</div>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4 mb-3">
                <div className="flex items-center gap-2">
                  <TrendingUp className="w-4 h-4 text-green-400" />
                  <div>
                    <div className="text-sm text-gray-400">APY</div>
                    <div className="font-semibold text-green-400">{pool.apy}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <DollarSign className="w-4 h-4 text-blue-400" />
                  <div>
                    <div className="text-sm text-gray-400">24h Volume</div>
                    <div className="font-semibold text-white">{pool.volume24h}</div>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 mb-3">
                <div className="flex items-center gap-2">
                  <Users className="w-4 h-4 text-purple-400" />
                  <div>
                    <div className="text-sm text-gray-400">Participants</div>
                    <div className="font-semibold text-white">{pool.participants}</div>
                  </div>
                </div>
                <div>
                  <div className="text-sm text-gray-400">24h Fees</div>
                  <div className="font-semibold text-white">{pool.fees24h}</div>
                </div>
              </div>

              {pool.myShare > 0 && (
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-400">My Share</span>
                    <span className="text-white">{pool.myShare}%</span>
                  </div>
                  <Progress value={pool.myShare} className="h-2" />
                </div>
              )}
            </motion.div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}