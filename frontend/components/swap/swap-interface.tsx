'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { ArrowUpDown, Settings, AlertTriangle, Info } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

const assetList = ['BTC', 'ETH', 'USDC', 'HYPE', 'UNI'];

export function SwapInterface() {
  const [fromAmount, setFromAmount] = useState('');
  const [toAmount, setToAmount] = useState('');
  const [slippage, setSlippage] = useState('0.5');
  const [showSettings, setShowSettings] = useState(false);
  const [fromToken, setFromToken] = useState(assetList[0]);
  const [toToken, setToToken] = useState(assetList[1]);

  const priceImpact = 0.8;
  const gasEstimate = '$12.50';
  const minimumReceived = '2,475.25';

  const handleSwap = () => {
    console.log('Swapping', fromAmount, fromToken, 'for', toAmount, toToken);
  };

  const handleFlipTokens = () => {
    const temp = fromToken;
    setFromToken(toToken);
    setToToken(temp);
    setFromAmount(toAmount);
    setToAmount(fromAmount);
  };

  return (
    <Card className="bg-black/20 border-white/10 backdrop-blur-sm">
      <CardHeader>
        <CardTitle className="flex items-center justify-between text-white">
          <span>Swap</span>
          <Button 
            variant="ghost" 
            size="icon"
            onClick={() => setShowSettings(!showSettings)}
          >
            <Settings className="w-4 h-4" />
          </Button>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {showSettings && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="p-4 bg-white/5 rounded-lg space-y-3"
          >
            <div>
              <label className="text-sm text-gray-400 mb-2 block">Slippage Tolerance</label>
              <div className="flex gap-2">
                {['0.1', '0.5', '1.0'].map((value) => (
                  <Button
                    key={value}
                    variant={slippage === value ? "default" : "outline"}
                    size="sm"
                    onClick={() => setSlippage(value)}
                    className="text-xs"
                  >
                    {value}%
                  </Button>
                ))}
                <Input
                  placeholder="Custom"
                  value={slippage}
                  onChange={(e) => setSlippage(e.target.value)}
                  className="w-20 text-xs"
                />
              </div>
            </div>
          </motion.div>
        )}

        {/* From Token */}
        <div className="p-4 bg-white/5 rounded-lg">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-gray-400">From</span>
            <span className="text-sm text-gray-400">
              Balance: 12.5483
            </span>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 min-w-24">
              <div className="w-6 h-6 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                <span className="text-white text-xs font-semibold">{fromToken.slice(0, 1)}</span>
              </div>
              <select
                value={fromToken}
                onChange={e => setFromToken(e.target.value)}
                className="bg-transparent text-white font-medium border-none outline-none"
              >
                {assetList.filter(asset => asset !== toToken).map(asset => (
                  <option key={asset} value={asset} className="text-black">{asset}</option>
                ))}
              </select>
            </div>
            <Input
              placeholder="0.0"
              value={fromAmount}
              onChange={(e) => setFromAmount(e.target.value)}
              className="flex-1"
            />
            <Button variant="outline" size="sm">
              Max
            </Button>
          </div>
        </div>

        {/* Swap Button */}
        <div className="flex justify-center">
          <Button
            variant="ghost"
            size="icon"
            onClick={handleFlipTokens}
            className="border border-white/20 bg-black/20 hover:bg-white/10"
          >
            <ArrowUpDown className="w-4 h-4" />
          </Button>
        </div>

        {/* To Token */}
        <div className="p-4 bg-white/5 rounded-lg">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-gray-400">To</span>
            <span className="text-sm text-gray-400">
              Balance: 8,420.00
            </span>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 min-w-24">
              <div className="w-6 h-6 bg-gradient-to-br from-purple-500 to-pink-600 rounded-full flex items-center justify-center">
                <span className="text-white text-xs font-semibold">{toToken.slice(0, 1)}</span>
              </div>
              <select
                value={toToken}
                onChange={e => setToToken(e.target.value)}
                className="bg-transparent text-white font-medium border-none outline-none"
              >
                {assetList.filter(asset => asset !== fromToken).map(asset => (
                  <option key={asset} value={asset} className="text-black">{asset}</option>
                ))}
              </select>
            </div>
            <Input
              placeholder="0.0"
              value={toAmount}
              onChange={(e) => setToAmount(e.target.value)}
              className="flex-1"
              readOnly
            />
          </div>
        </div>

        {/* Trade Details */}
        {fromAmount && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-2 p-4 bg-white/5 rounded-lg"
          >
            <div className="flex justify-between text-sm">
              <span className="text-gray-400">Price Impact</span>
              <div className="flex items-center gap-1">
                <Badge variant={priceImpact > 2 ? "destructive" : "default"}>
                  {priceImpact}%
                </Badge>
                {priceImpact > 2 && <AlertTriangle className="w-4 h-4 text-red-400" />}
              </div>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-gray-400">Minimum Received</span>
              <span className="text-white">{minimumReceived} {toToken}</span>
            </div>
            <div className="flex justify-between text-sm">
              <div className="flex items-center gap-1">
                <span className="text-gray-400">Gas Estimate</span>
                <TooltipProvider>
                  <Tooltip>
                    <TooltipTrigger>
                      <Info className="w-3 h-3 text-gray-400" />
                    </TooltipTrigger>
                    <TooltipContent>
                      <p>Estimated gas cost for this transaction</p>
                    </TooltipContent>
                  </Tooltip>
                </TooltipProvider>
              </div>
              <span className="text-white">{gasEstimate}</span>
            </div>
          </motion.div>
        )}

        <Button
          onClick={handleSwap}
          className="w-full bg-blue-600 hover:bg-blue-700"
          disabled={!fromAmount || !toAmount}
        >
          {!fromAmount || !toAmount ? 'Enter Amount' : `Swap ${fromToken} for ${toToken}`}
        </Button>
      </CardContent>
    </Card>
  );
}