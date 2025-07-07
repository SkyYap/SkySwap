'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Droplets, Search } from 'lucide-react';

const pools = [
  { pair: 'ETH/USSKY', apy: '24.5%', tvl: '$12.4M', volume: '$1.9M' },
  { pair: 'BTC/USSKY', apy: '18.7%', tvl: '$8.9M', volume: '$1.2M' },
  { pair: 'UNI/USSKY', apy: '32.1%', tvl: '$4.2M', volume: '$800K' },
  { pair: 'LINK/USSKY', apy: '28.9%', tvl: '$3.8M', volume: '$650K' },
  { pair: 'AAVE/USSKY', apy: '41.2%', tvl: '$2.1M', volume: '$420K' },
];

const generateChartData = (pair: string) => {
  const baseValue = pair.includes('ETH') ? 18.5 : pair.includes('BTC') ? 15.2 : 25.0;
  return [
    { time: '00:00', apy: baseValue, volume: 1200000 },
    { time: '04:00', apy: baseValue + 0.7, volume: 1450000 },
    { time: '08:00', apy: baseValue + 3.6, volume: 1800000 },
    { time: '12:00', apy: baseValue + 6.0, volume: 2100000 },
    { time: '16:00', apy: baseValue + 8.3, volume: 2300000 },
    { time: '20:00', apy: baseValue + 6.0, volume: 1900000 },
  ];
};

interface LiquidityChartProps {
  selectedPool: string;
  onPoolChange: (pool: string) => void;
}

export function LiquidityChart({ selectedPool, onPoolChange }: LiquidityChartProps) {
  const [searchTerm, setSearchTerm] = useState('');
  
  const currentPool = pools.find(p => p.pair === selectedPool) || pools[0];
  const data = generateChartData(selectedPool);
  
  const filteredPools = pools.filter(pool => 
    pool.pair.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center justify-between text-white">
          <div className="flex items-center gap-2">
            <Droplets className="w-5 h-5" />
            Pool Performance
          </div>
          <Badge variant="outline" className="text-green-400 border-green-400">
            APY: {currentPool.apy}
          </Badge>
        </CardTitle>
        
        {/* Pool Selector */}
        <div className="space-y-2">
          <Select value={selectedPool} onValueChange={onPoolChange}>
            <SelectTrigger className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <div className="p-2">
                <div className="relative mb-2">
                  <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input 
                    placeholder="Search pools..." 
                    className="pl-8 text-sm"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                  />
                </div>
              </div>
              {filteredPools.map((pool) => (
                <SelectItem key={pool.pair} value={pool.pair}>
                  <div className="flex items-center gap-3 w-full">
                    <div className="w-6 h-6 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                      <span className="text-white text-xs font-semibold">
                        {pool.pair.split('/')[0].slice(0, 1)}{pool.pair.split('/')[1].slice(0, 1)}
                      </span>
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <span className="font-medium">{pool.pair}</span>
                        <Badge variant="outline" className="text-xs text-green-400">
                          {pool.apy}
                        </Badge>
                      </div>
                      <div className="text-xs text-gray-400">TVL: {pool.tvl}</div>
                    </div>
                  </div>
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div>
            <div className="text-2xl font-bold text-white">{currentPool.tvl}</div>
            <div className="text-sm text-gray-400">Total Liquidity</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-white">{currentPool.volume}</div>
            <div className="text-sm text-gray-400">24h Volume</div>
          </div>
        </div>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data}>
              <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
              <XAxis dataKey="time" stroke="#9CA3AF" />
              <YAxis stroke="#9CA3AF" />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: '#1F2937', 
                  border: '1px solid #374151',
                  borderRadius: '8px'
                }}
              />
              <Area 
                type="monotone" 
                dataKey="apy" 
                stroke="#3B82F6" 
                fill="url(#colorApy)"
                strokeWidth={2}
              />
              <defs>
                <linearGradient id="colorApy" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#3B82F6" stopOpacity={0}/>
                </linearGradient>
              </defs>
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}