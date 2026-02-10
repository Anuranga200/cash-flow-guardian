import { useState } from 'react';
import { ChevronDown, ChevronUp, Lightbulb, TrendingUp } from 'lucide-react';
import { formatCurrency, mlForecasts } from '@/data/mockData';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, Area, AreaChart, ReferenceLine } from 'recharts';

export function MLForecastSection() {
  const [expanded, setExpanded] = useState(false);

  const nextWeekOutflow = mlForecasts
    .slice(0, 7)
    .reduce((sum, f) => sum + f.predictedOutflow, 0);

  const chartData = mlForecasts.map((f) => ({
    date: new Date(f.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }),
    outflow: f.predictedOutflow,
  }));

  return (
    <section>
      <div className="mb-3 flex items-center justify-between">
        <h2 className="section-title">📈 Cash Flow Forecast</h2>
        <button
          onClick={() => setExpanded(!expanded)}
          className="flex items-center gap-1 text-sm font-medium text-accent"
        >
          {expanded ? 'Simple' : 'Advanced'}
          {expanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
        </button>
      </div>

      <div className="rounded-xl border border-border/50 bg-card p-4 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-info/10">
            <TrendingUp className="h-5 w-5 text-info" />
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Next week expected outflow</p>
            <p className="text-xl font-bold text-card-foreground">{formatCurrency(nextWeekOutflow)}</p>
          </div>
        </div>

        {expanded && (
          <div className="mt-5 space-y-4">
            <div className="h-48">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="outflowGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="hsl(210, 80%, 56%)" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="hsl(210, 80%, 56%)" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="date" tick={{ fontSize: 10 }} interval="preserveStartEnd" />
                  <YAxis tick={{ fontSize: 10 }} tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}k`} width={50} />
                  <Tooltip
                    formatter={(value: number) => [formatCurrency(value), 'Outflow']}
                    contentStyle={{ borderRadius: '8px', fontSize: '12px', border: '1px solid hsl(214, 20%, 90%)' }}
                  />
                  <ReferenceLine y={150000} stroke="hsl(38, 92%, 50%)" strokeDasharray="3 3" label={{ value: 'High', fontSize: 10, fill: 'hsl(38, 92%, 50%)' }} />
                  <Area type="monotone" dataKey="outflow" stroke="hsl(210, 80%, 56%)" fill="url(#outflowGrad)" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            </div>

            <div className="rounded-lg border border-accent/20 bg-accent/5 p-3">
              <div className="flex items-start gap-2">
                <Lightbulb className="mt-0.5 h-4 w-4 text-accent shrink-0" />
                <div>
                  <p className="text-sm font-semibold text-card-foreground">Payment Optimization</p>
                  <p className="mt-0.5 text-xs text-muted-foreground">
                    Issue cheque dated Feb 20 instead of Feb 15 to maintain safe balance. This avoids a potential deficit of ₹85,000.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
