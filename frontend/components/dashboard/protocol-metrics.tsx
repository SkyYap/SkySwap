'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { TrendingUp, DollarSign, Activity, Users } from 'lucide-react';

const metrics = [
  {
    title: 'Total Value Locked',
    value: '$2.4B',
    change: '+12.3%',
    icon: DollarSign,
    color: 'text-green-400'
  },
  {
    title: '24h Volume',
    value: '$156.8M',
    change: '+8.7%',
    icon: Activity,
    color: 'text-blue-400'
  },
  {
    title: 'Fee Revenue',
    value: '$1.2M',
    change: '+15.2%',
    icon: TrendingUp,
    color: 'text-purple-400'
  },
  {
    title: 'Active Positions',
    value: '12,847',
    change: '+5.4%',
    icon: Users,
    color: 'text-orange-400'
  }
];

export function ProtocolMetrics() {
  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="text-white">Protocol Metrics</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {metrics.map((metric, index) => (
          <motion.div
            key={metric.title}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.3, delay: index * 0.1 }}
            className="p-4 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
          >
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <metric.icon className={`w-4 h-4 ${metric.color}`} />
                <span className="text-gray-400 text-sm">{metric.title}</span>
              </div>
              <span className="text-green-400 text-sm">{metric.change}</span>
            </div>
            <div className="text-2xl font-bold text-white">{metric.value}</div>
          </motion.div>
        ))}
      </CardContent>
    </Card>
  );
}