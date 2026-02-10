import { useState } from 'react';
import { PageHeader } from '@/components/layout/PageHeader';
import { cheques, getSupplierById, formatCurrency, suppliers } from '@/data/mockData';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Download, FileSpreadsheet } from 'lucide-react';
import { ChequeStatus } from '@/types';
import { toast } from 'sonner';

export default function ReportsPage() {
  const [statusFilter, setStatusFilter] = useState<ChequeStatus | 'all'>('all');
  const [supplierFilter, setSupplierFilter] = useState('all');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const filtered = cheques.filter((c) => {
    if (statusFilter !== 'all' && c.status !== statusFilter) return false;
    if (supplierFilter !== 'all' && c.supplierId !== supplierFilter) return false;
    if (dateFrom && c.chequeDate < dateFrom) return false;
    if (dateTo && c.chequeDate > dateTo) return false;
    return true;
  });

  const totalAmount = filtered.reduce((s, c) => s + c.amount, 0);

  const handleExport = () => {
    toast.success(`Exporting ${filtered.length} cheques to Excel`);
  };

  return (
    <div className="min-h-screen bg-background">
      <PageHeader title="Reports" />
      <div className="page-container space-y-5">
        <div className="rounded-xl border border-border/50 bg-card p-4 shadow-sm space-y-4">
          <h2 className="font-semibold text-card-foreground">Filters</h2>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label className="text-xs">From</Label>
              <Input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs">To</Label>
              <Input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label className="text-xs">Status</Label>
            <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as ChequeStatus | 'all')}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Statuses</SelectItem>
                <SelectItem value="upcoming">Upcoming</SelectItem>
                <SelectItem value="issued">Issued</SelectItem>
                <SelectItem value="cleared">Cleared</SelectItem>
                <SelectItem value="bounced">Bounced</SelectItem>
                <SelectItem value="cancelled">Cancelled</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-1.5">
            <Label className="text-xs">Supplier</Label>
            <Select value={supplierFilter} onValueChange={setSupplierFilter}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Suppliers</SelectItem>
                {suppliers.map(s => <SelectItem key={s.id} value={s.id}>{s.company}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>
        </div>

        <div className="rounded-xl border border-border/50 bg-card p-4 shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <div>
              <p className="text-sm text-muted-foreground">{filtered.length} cheques found</p>
              <p className="text-lg font-bold text-card-foreground">{formatCurrency(totalAmount)}</p>
            </div>
            <Button onClick={handleExport} className="gap-2 bg-accent text-accent-foreground hover:bg-accent/90">
              <Download className="h-4 w-4" /> Export
            </Button>
          </div>

          <div className="space-y-2 max-h-80 overflow-y-auto">
            {filtered.map((cheque) => {
              const supplier = getSupplierById(cheque.supplierId);
              return (
                <div key={cheque.id} className="flex items-center justify-between rounded-lg bg-muted/50 p-3">
                  <div>
                    <p className="text-sm font-medium text-card-foreground">{supplier?.company}</p>
                    <p className="text-xs text-muted-foreground capitalize">{cheque.chequeNumber} · {cheque.status}</p>
                  </div>
                  <p className="font-semibold text-card-foreground">{formatCurrency(cheque.amount)}</p>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
