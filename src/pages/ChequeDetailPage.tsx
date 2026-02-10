import { useParams, useNavigate } from 'react-router-dom';
import { PageHeader } from '@/components/layout/PageHeader';
import { cheques, getSupplierById, getBankAccountById, formatCurrency } from '@/data/mockData';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { CheckCircle2, XCircle, FileText, Building2, Calendar, Hash, StickyNote } from 'lucide-react';
import { ChequeStatus } from '@/types';
import { useState } from 'react';
import { toast } from 'sonner';

const statusOptions: ChequeStatus[] = ['issued', 'upcoming', 'cleared', 'bounced', 'cancelled'];

export default function ChequeDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const cheque = cheques.find(c => c.id === id);
  const [status, setStatus] = useState<ChequeStatus>(cheque?.status ?? 'issued');

  if (!cheque) {
    return (
      <div className="min-h-screen bg-background">
        <PageHeader title="Cheque Details" showBack />
        <div className="page-container text-center text-muted-foreground py-20">Cheque not found</div>
      </div>
    );
  }

  const supplier = getSupplierById(cheque.supplierId);
  const bank = getBankAccountById(cheque.bankAccountId);

  const handleStatusChange = (newStatus: ChequeStatus) => {
    setStatus(newStatus);
    toast.success(`Status updated to ${newStatus}`);
  };

  const details = [
    { icon: Building2, label: 'Supplier', value: supplier?.company },
    { icon: Hash, label: 'Cheque No.', value: cheque.chequeNumber },
    { icon: Calendar, label: 'Cheque Date', value: new Date(cheque.chequeDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' }) },
    { icon: FileText, label: 'Amount', value: formatCurrency(cheque.amount) },
    { icon: Building2, label: 'Bank', value: `${bank?.bankName} - ${bank?.accountName}` },
    { icon: StickyNote, label: 'Notes', value: cheque.notes || 'No notes' },
  ];

  return (
    <div className="min-h-screen bg-background">
      <PageHeader title="Cheque Details" showBack />
      <div className="page-container space-y-5">
        {cheque.imageUrl && (
          <div className="overflow-hidden rounded-xl border border-border">
            <img src={cheque.imageUrl} alt="Cheque" className="w-full" />
          </div>
        )}

        <div className="rounded-xl border border-border/50 bg-card shadow-sm divide-y divide-border">
          {details.map((d) => (
            <div key={d.label} className="flex items-start gap-3 p-3.5">
              <d.icon className="mt-0.5 h-4 w-4 text-muted-foreground shrink-0" />
              <div className="min-w-0">
                <p className="text-xs text-muted-foreground">{d.label}</p>
                <p className="text-sm font-medium text-card-foreground">{d.value}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="rounded-xl border border-border/50 bg-card p-4 shadow-sm">
          <label className="text-xs text-muted-foreground mb-2 block">Status</label>
          <Select value={status} onValueChange={(v) => handleStatusChange(v as ChequeStatus)}>
            <SelectTrigger className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {statusOptions.map((s) => (
                <SelectItem key={s} value={s} className="capitalize">{s}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Button
            onClick={() => { handleStatusChange('cleared'); }}
            className="gap-2 bg-success text-success-foreground hover:bg-success/90"
          >
            <CheckCircle2 className="h-4 w-4" /> Mark Cleared
          </Button>
          <Button
            variant="destructive"
            onClick={() => { handleStatusChange('bounced'); }}
            className="gap-2"
          >
            <XCircle className="h-4 w-4" /> Mark Bounced
          </Button>
        </div>
      </div>
    </div>
  );
}
