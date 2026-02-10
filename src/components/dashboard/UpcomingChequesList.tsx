import { useNavigate } from 'react-router-dom';
import { cheques, getSupplierById, formatCurrency, getDaysRemaining } from '@/data/mockData';
import { Badge } from '@/components/ui/badge';
import { ChevronRight } from 'lucide-react';

export function UpcomingChequesList() {
  const navigate = useNavigate();

  const upcomingCheques = cheques
    .filter(c => {
      const days = getDaysRemaining(c.chequeDate);
      return days >= 0 && days <= 7 && (c.status === 'upcoming' || c.status === 'issued');
    })
    .sort((a, b) => new Date(a.chequeDate).getTime() - new Date(b.chequeDate).getTime());

  return (
    <section>
      <div className="mb-3 flex items-center justify-between">
        <h2 className="section-title">🔔 Upcoming Reminders</h2>
        <button onClick={() => navigate('/cheques')} className="text-sm font-medium text-accent">
          View All
        </button>
      </div>
      <div className="space-y-2">
        {upcomingCheques.map((cheque) => {
          const supplier = getSupplierById(cheque.supplierId);
          const daysLeft = getDaysRemaining(cheque.chequeDate);

          return (
            <button
              key={cheque.id}
              onClick={() => navigate(`/cheques/${cheque.id}`)}
              className="flex w-full items-center gap-3 rounded-xl bg-card p-3.5 text-left shadow-sm border border-border/50 transition-all hover:shadow-md active:scale-[0.99]"
            >
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-card-foreground truncate">{supplier?.company}</p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  {cheque.chequeNumber} · {new Date(cheque.chequeDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}
                </p>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <div className="text-right">
                  <p className="font-bold text-card-foreground">{formatCurrency(cheque.amount)}</p>
                  <DaysRemainingBadge days={daysLeft} />
                </div>
                <ChevronRight className="h-4 w-4 text-muted-foreground" />
              </div>
            </button>
          );
        })}
        {upcomingCheques.length === 0 && (
          <p className="py-8 text-center text-sm text-muted-foreground">No upcoming cheques in the next 7 days</p>
        )}
      </div>
    </section>
  );
}

function DaysRemainingBadge({ days }: { days: number }) {
  const variant = days <= 1 ? 'destructive' : days <= 3 ? 'outline' : 'secondary';
  const label = days === 0 ? 'Today' : days === 1 ? 'Tomorrow' : `${days}d left`;

  return (
    <Badge variant={variant} className="text-[10px] px-1.5 py-0">
      {label}
    </Badge>
  );
}
