'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { TrendingUp, Search } from 'lucide-react';

const tradingPairs = [
  { pair: 'ETH/USSKY', price: '$2,495.32', change: '+0.6%', positive: true, volume: '$1.9M' },
  { pair: 'BTC/USSKY', price: '$43,250.00', change: '+1.2%', positive: true, volume: '$2.4M' },
  { pair: 'UNI/USSKY', price: '$7.52', change: '-2.1%', positive: false, volume: '$850K' },
  { pair: 'LINK/USSKY', price: '$14.25', change: '+3.4%', positive: true, volume: '$720K' },
  { pair: 'AAVE/USSKY', price: '$89.50', change: '+5.7%', positive: true, volume: '$560K' },
  { pair: 'COMP/USSKY', price: '$45.80', change: '-1.8%', positive: false, volume: '$340K' },
];

const generateChartData = (pair: string) => {
  const basePrice = pair.includes('ETH') ? 2480 : 
                   pair.includes('BTC') ? 43000 : 
                   pair.includes('UNI') ? 7.2 : 
                   pair.includes('LINK') ? 13.8 : 
                   pair.includes('AAVE') ? 85.0 : 44.0;
  
  return [
    { time: '00:00', price: basePrice },
    { time: '04:00', price: basePrice + (basePrice * 0.005) },
    { time: '08:00', price: basePrice - (basePrice * 0.002) },
    { time: '12:00', price: basePrice + (basePrice * 0.013) },
    { time: '16:00', price: basePrice + (basePrice * 0.018) },
    { time: '20:00', price: basePrice + (basePrice * 0.006) },
  ];
};

interface SwapChartProps {
  selectedPair: string;
  onPairChange: (pair: string) => void;
}

export function SwapChart({ selectedPair, onPairChange }: SwapChartProps) {
  const [searchTerm, setSearchTerm] = useState('');
  
  const currentPair = tradingPairs.find(p => p.pair === selectedPair) || tradingPairs[0];
  const data = generateChartData(selectedPair || tradingPairs[0].pair);
  
  const filteredPairs = tradingPairs.filter(pair => 
    pair.pair.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center justify-between text-white">
          <div className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5" />
            Trading Chart
          </div>
          <Badge 
            variant="outline" 
            className={`${currentPair.positive ? 'text-green-400 border-green-400' : 'text-red-400 border-red-400'}`}
          >
            {currentPair.change} (24h)
          </Badge>
        </CardTitle>
        
        {/* Pair Selector */}
        <div className="space-y-2">
          <Select value={selectedPair} onValueChange={onPairChange}>
            <SelectTrigger className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <div className="p-2">
                <div className="relative mb-2">
                  <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input 
                    placeholder="Search pairs..." 
                    className="pl-8 text-sm"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                  />
                </div>
              </div>
              {filteredPairs.map((pair) => (
                <SelectItem key={pair.pair} value={pair.pair}>
                  <div className="flex items-center gap-3 w-full">
                    <div className="w-6 h-6 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                      <span className="text-white text-xs font-semibold">
                        {pair.pair.split('/')[0].slice(0, 1)}{pair.pair.split('/')[1].slice(0, 1)}
                      </span>
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <span className="font-medium">{pair.pair}</span>
                        <Badge 
                          variant="outline" 
                          className={`text-xs ${pair.positive ? 'text-green-400' : 'text-red-400'}`}
                        >
                          {pair.change}
                        </Badge>
                      </div>
                      <div className="text-xs text-gray-400">Vol: {pair.volume}</div>
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
            <div className="text-2xl font-bold text-white">{currentPair.price}</div>
            <div className="text-sm text-gray-400">Current Price</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-white">{currentPair.volume}</div>
            <div className="text-sm text-gray-400">24h Volume</div>
          </div>
        </div>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data}>
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
              <Line 
                type="monotone" 
                dataKey="price" 
                stroke={currentPair.positive ? "#10B981" : "#EF4444"}
                strokeWidth={2}
                dot={{ fill: currentPair.positive ? "#10B981" : "#EF4444", strokeWidth: 2 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}