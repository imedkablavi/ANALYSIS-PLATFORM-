function rho = spearmanRho(a, b)
%SPEARMANRHO Spearman rank correlation (Pearson on tied ranks), NaN-safe.

a = a(:);
b = b(:);
ok = ~isnan(a) & ~isnan(b);
if nnz(ok) < 3
    rho = NaN;
    return;
end
ra = tiedRanks(a(ok));
rb = tiedRanks(b(ok));
ra = ra - mean(ra);
rb = rb - mean(rb);
den = sqrt(sum(ra.^2) * sum(rb.^2));
if den == 0
    rho = NaN;
else
    rho = sum(ra .* rb) / den;
end
end
