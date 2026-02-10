import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '@/components/layout/PageHeader';
import { cheques, getSupplierById, formatCurrency, getDaysRemaining } from '@/data/mockData';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Plus, ChevronRight } from 'lucide-react';
import { ChequeStatus } from '@/types';

const statusColors: Record<ChequeStatus, string> = {
  upcoming: 'bg-warning/15 text-warning-foreground border-warning/30',
  issued: 'bg-info/15 text-info border-info/30',
  cleared: 'bg-success/15 text-success border-success/30',
  bounced: 'bg-destructive/15 text-destructive border-destructive/30',
  cancelled: 'bg-muted text-muted-foreground border-border',
};

export default function ChequesPage() {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<ChequeStatus | 'all'>('all');

  const filtered = filter === 'all' ? cheques : cheques.filter(c => c.status === filter);
  const sorted = [...filtered].sort((a, b) => new Date(b.chequeDate).getTime() - new Date(a.chequeDate).getTime());

  const filters: Array<ChequeStatus | 'all'> = ['all', 'upcoming', 'issued', 'cleared', 'bounced', 'cancelled'];

  return (
    <div className="min-h-screen bg-background">
      <PageHeader
        title="Cheques"
        rightAction={
          <Button size="sm" onClick={() => navigate('/cheques/new')} className="gap-1 bg-accent text-accent-foreground hover:bg-accent/90">
            <Plus className="h-4 w-4" /> New
          </Button>
        }
      />
      <div className="page-container">
        <div className="mb-4 flex gap-2 overflow-x-auto pb-1 no-scrollbar">
          {filters.map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`shrink-0 rounded-full px-3 py-1.5 text-xs font-medium capitalize transition-colors ${
                filter === f
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-secondary text-secondary-foreground'
              }`}
            >
              {f}
            </button>
          ))}
        </div>

        <div className="space-y-2">
          {sorted.map((cheque) => {
            const supplier = getSupplierById(cheque.supplierId);
            const daysLeft = getDaysRemaining(cheque.chequeDate);

            return (
              <button
                key={cheque.id}
                onClick={() => navigate(`/cheques/${cheque.id}`)}
                className="flex w-full items-center gap-3 rounded-xl bg-card p-3.5 text-left shadow-sm border border-border/50 transition-all hover:shadow-md"
              >
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-card-foreground truncate">{supplier?.company}</p>
                  <p className="mt-0.5 text-xs text-muted-foreground">
                    {cheque.chequeNumber} · {new Date(cheque.chequeDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </p>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <div className="text-right">
                    <p className="font-bold text-card-foreground">{formatCurrency(cheque.amount)}</p>
                    <span className={`inline-block mt-0.5 rounded-full border px-2 py-0.5 text-[10px] font-medium capitalize ${statusColors[cheque.status]}`}>
                      {cheque.status}
                    </span>
                  </div>
                  <ChevronRight className="h-4 w-4 text-muted-foreground" />
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
