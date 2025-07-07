'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Clock, ExternalLink, ArrowLeftRight, Droplets, Minus } from 'lucide-react';

const activities = [
  {
    type: 'Swap',
    description: 'Swapped 2.5 ETH for 6,247.50 USDC',
    time: '2 minutes ago',
    status: 'Completed',
    hash: '0x1234...5678',
    icon: ArrowLeftRight
  },
  {
    type: 'Add Liquidity',
    description: 'Added liquidity to ETH/USDC pool',
    time: '15 minutes ago',
    status: 'Completed',
    hash: '0x2345...6789',
    icon: Droplets
  },
  {
    type: 'Remove Liquidity',
    description: 'Removed liquidity from WBTC/ETH pool',
    time: '1 hour ago',
    status: 'Completed',
    hash: '0x3456...7890',
    icon: Minus
  },
  {
    type: 'Swap',
    description: 'Swapped 1,000 USDC for 0.4 ETH',
    time: '3 hours ago',
    status: 'Completed',
    hash: '0x4567...8901',
    icon: ArrowLeftRight
  },
  {
    type: 'Add Liquidity',
    description: 'Added liquidity to UNI/USDC pool',
    time: '1 day ago',
    status: 'Completed',
    hash: '0x5678...9012',
    icon: Droplets
  }
];

export function ActivityHistory() {
  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-white">
          <Clock className="w-5 h-5" />
          Activity History
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {activities.map((activity, index) => (
            <motion.div
              key={activity.hash}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: index * 0.1 }}
              className="flex items-center justify-between p-4 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
            >
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                  <activity.icon className="w-5 h-5 text-white" />
                </div>
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <Badge variant="outline" className="text-xs">
                      {activity.type}
                    </Badge>
                    <span className="text-sm text-gray-400">{activity.time}</span>
                  </div>
                  <div className="text-white">{activity.description}</div>
                  <div className="text-xs text-gray-400">Tx: {activity.hash}</div>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Badge variant="default" className="text-xs">
                  {activity.status}
                </Badge>
                <Button variant="ghost" size="icon" className="text-gray-400 hover:text-white">
                  <ExternalLink className="w-4 h-4" />
                </Button>
              </div>
            </motion.div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}