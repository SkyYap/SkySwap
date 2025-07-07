'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Slider } from '@/components/ui/slider';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Shield, AlertTriangle, Info, ArrowLeft, TrendingDown } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

interface HedgingInterfaceProps {
  onBack: () => void;
}

export function HedgingInterface({ onBack }: HedgingInterfaceProps) {
  const [hedgeRatio, setHedgeRatio] = useState([70]);
  const [leverage, setLeverage] = useState('3');
  const [usdcAmount, setUsdcAmount] = useState('');
  const [autoUnwind, setAutoUnwind] = useState(true);
  const [continuationStrategy, setContinuationStrategy] = useState('rebalance');

  const liquidationPrice = '$1,847.32';
  const gasCost = '$45.60';
  const collateralRatio = '175%';

  const handleConfirmHedging = () => {
    // Confirm hedging logic here
    console.log('Confirming hedging with:', {
      hedgeRatio: hedgeRatio[0],
      leverage,
      usdcAmount,
      autoUnwind,
      continuationStrategy
    });
  };

  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-white">
          <Button variant="ghost" size="icon" onClick={onBack}>
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <Shield className="w-5 h-5" />
          Advanced Hedging
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Hedge Ratio */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-white font-medium">ETH Exposure Hedge</span>
              <TooltipProvider>
                <Tooltip>
                  <TooltipTrigger>
                    <Info className="w-3 h-3 text-gray-400" />
                  </TooltipTrigger>
                  <TooltipContent>
                    <p>Percentage of ETH exposure to hedge against price movements</p>
                  </TooltipContent>
                </Tooltip>
              </TooltipProvider>
            </div>
            <Badge variant="outline">{hedgeRatio[0]}%</Badge>
          </div>
          <Slider
            value={hedgeRatio}
            onValueChange={setHedgeRatio}
            max={100}
            min={0}
            step={5}
            className="w-full"
          />
          <div className="flex justify-between text-xs text-gray-400">
            <span>0%</span>
            <span>50%</span>
            <span>100%</span>
          </div>
        </div>

        {/* Leverage */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-white font-medium">Leverage</span>
            <Badge variant={parseInt(leverage) > 5 ? "destructive" : "default"}>
              {leverage}x
            </Badge>
          </div>
          <Select value={leverage} onValueChange={setLeverage}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {['1', '2', '3', '5', '10'].map((lev) => (
                <SelectItem key={lev} value={lev}>
                  {lev}x {parseInt(lev) > 5 && '⚠️'}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* USDC Collateral */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-white font-medium">USDC Collateral</span>
            <span className="text-sm text-gray-400">Balance: 8,420.00</span>
          </div>
          <div className="flex gap-2">
            <Input
              placeholder="0.0"
              value={usdcAmount}
              onChange={(e) => setUsdcAmount(e.target.value)}
              className="flex-1"
            />
            <Button variant="outline" size="sm">
              Max
            </Button>
          </div>
        </div>

        {/* Risk Metrics */}
        <div className="p-4 bg-red-500/10 border border-red-500/20 rounded-lg">
          <div className="flex items-center gap-2 mb-3">
            <AlertTriangle className="w-4 h-4 text-red-400" />
            <span className="text-red-400 font-medium">Risk Metrics</span>
          </div>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-400">Liquidation Price</span>
              <span className="text-red-400">{liquidationPrice}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Collateral Ratio</span>
              <span className="text-white">{collateralRatio}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Automation Gas Cost</span>
              <span className="text-white">{gasCost}</span>
            </div>
          </div>
        </div>

        {/* Risk Management */}
        <div className="space-y-4">
          <h3 className="text-white font-medium">Risk Management</h3>
          
          <div className="flex items-center justify-between p-3 bg-white/5 rounded-lg">
            <div>
              <div className="text-white text-sm">Auto Position Unwinding</div>
              <div className="text-gray-400 text-xs">Automatically close position on liquidation risk</div>
            </div>
            <Switch
              checked={autoUnwind}
              onCheckedChange={setAutoUnwind}
            />
          </div>

          <div className="space-y-2">
            <label className="text-white text-sm">Continuation Strategy</label>
            <Select value={continuationStrategy} onValueChange={setContinuationStrategy}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="rebalance">Auto Rebalance</SelectItem>
                <SelectItem value="close">Close Position</SelectItem>
                <SelectItem value="maintain">Maintain Exposure</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        {/* Warnings */}
        {parseInt(leverage) > 5 && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="p-4 bg-yellow-500/10 border border-yellow-500/20 rounded-lg"
          >
            <div className="flex items-center gap-2 mb-2">
              <AlertTriangle className="w-4 h-4 text-yellow-400" />
              <span className="text-yellow-400 font-medium">High Leverage Warning</span>
            </div>
            <div className="text-sm text-gray-400">
              High leverage increases liquidation risk. Consider reducing leverage for safer trading.
            </div>
          </motion.div>
        )}

        <Button
          onClick={handleConfirmHedging}
          className="w-full bg-blue-600 hover:bg-blue-700"
          disabled={!usdcAmount}
        >
          {!usdcAmount ? 'Enter USDC Amount' : 'Confirm Hedging Setup'}
        </Button>
      </CardContent>
    </Card>
  );
}