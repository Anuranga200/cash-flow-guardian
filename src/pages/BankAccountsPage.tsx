import { PageHeader } from '@/components/layout/PageHeader';
import { bankAccounts, formatCurrency } from '@/data/mockData';
import { Landmark } from 'lucide-react';

export default function BankAccountsPage() {
  const totalBalance = bankAccounts.reduce((sum, b) => sum + b.currentBalance, 0);

  return (
    <div className="min-h-screen bg-background">
      <PageHeader title="Bank Accounts" />
      <div className="page-container space-y-5">
        <div className="rounded-xl stat-card-gradient p-5 text-primary-foreground">
          <p className="text-sm opacity-80">Total Balance</p>
          <p className="text-2xl font-bold mt-1">{formatCurrency(totalBalance)}</p>
        </div>

        <div className="space-y-3">
          {bankAccounts.map((account) => (
            <div key={account.id} className="rounded-xl border border-border/50 bg-card p-4 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10">
                  <Landmark className="h-5 w-5 text-primary" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-card-foreground">{account.bankName}</p>
                  <p className="text-xs text-muted-foreground">{account.accountName}</p>
                </div>
              </div>
              <div className="mt-3 flex items-end justify-between">
                <div>
                  <p className="text-xs text-muted-foreground">Current Balance</p>
                  <p className="text-xl font-bold text-card-foreground">{formatCurrency(account.currentBalance)}</p>
                </div>
                <p className="text-xs text-muted-foreground">
                  Updated {new Date(account.lastUpdated).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
