import { CalendarClock, IndianRupee, Landmark, Brain } from 'lucide-react';
import { cheques, bankAccounts, formatCurrency, getDaysRemaining } from '@/data/mockData';

export function SummaryCards() {
  const upcomingCheques = cheques.filter(c => {
    const days = getDaysRemaining(c.chequeDate);
    return days >= 0 && days <= 7 && (c.status === 'upcoming' || c.status === 'issued');
  });

  const totalClearing = upcomingCheques.reduce((sum, c) => sum + c.amount, 0);
  const totalBalance = bankAccounts.reduce((sum, b) => sum + b.currentBalance, 0);
  const nextWeekOutflow = 425000; // ML predicted

  const cards = [
    {
      label: 'Upcoming (7 Days)',
      value: `${upcomingCheques.length} Cheques`,
      icon: CalendarClock,
      className: 'stat-card-gradient text-primary-foreground',
    },
    {
      label: 'Clearing Soon',
      value: formatCurrency(totalClearing),
      icon: IndianRupee,
      className: 'warning-gradient text-warning-foreground',
    },
    {
      label: 'Total Balance',
      value: formatCurrency(totalBalance),
      icon: Landmark,
      className: 'accent-gradient text-accent-foreground',
    },
    {
      label: 'ML: Next Week',
      value: formatCurrency(nextWeekOutflow),
      icon: Brain,
      className: 'info-gradient text-info-foreground',
    },
  ];

  return (
    <div className="grid grid-cols-2 gap-3">
      {cards.map((card) => (
        <div key={card.label} className={`rounded-xl p-4 ${card.className}`}>
          <div className="flex items-center gap-2 opacity-90">
            <card.icon className="h-4 w-4" />
            <span className="text-xs font-medium">{card.label}</span>
          </div>
          <p className="mt-2 text-lg font-bold leading-tight">{card.value}</p>
        </div>
      ))}
    </div>
  );
}
