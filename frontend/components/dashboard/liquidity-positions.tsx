'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Droplets, TrendingUp, Clock } from 'lucide-react';

const positions = [
  {
    pair: 'ETH/USDC',
    tvl: '$12,450.32',
    apy: '24.5%',
    timeInPosition: '12 days',
    share: '0.12%',
    status: 'Active'
  },
  {
    pair: 'WBTC/ETH',
    tvl: '$8,920.15',
    apy: '18.7%',
    timeInPosition: '8 days',
    share: '0.08%',
    status: 'Active'
  },
  {
    pair: 'UNI/USDC',
    tvl: '$3,240.87',
    apy: '32.1%',
    timeInPosition: '5 days',
    share: '0.05%',
    status: 'Active'
  },
];

export function LiquidityPositions() {
  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-white">
          <Droplets className="w-5 h-5" />
          Liquidity Positions
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {positions.map((position, index) => (
            <motion.div
              key={position.pair}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: index * 0.1 }}
              className="p-4 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                    <Droplets className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <div className="font-semibold text-white">{position.pair}</div>
                    <Badge variant="outline" className="text-xs">
                      {position.status}
                    </Badge>
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-semibold text-white">{position.tvl}</div>
                  <div className="text-sm text-gray-400">Pool Share: {position.share}</div>
                </div>
              </div>
              
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
                <div className="flex items-center gap-2">
                  <TrendingUp className="w-4 h-4 text-green-400" />
                  <div>
                    <div className="text-gray-400">APY</div>
                    <div className="font-semibold text-green-400">{position.apy}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-blue-400" />
                  <div>
                    <div className="text-gray-400">Time</div>
                    <div className="font-semibold text-white">{position.timeInPosition}</div>
                  </div>
                </div>
                <div className="flex justify-end">
                  <Button variant="outline" size="sm" className="text-xs">
                    Manage
                  </Button>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}