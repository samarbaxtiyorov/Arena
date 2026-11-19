// ============================================
// Arena — Qarzdor Mijoz Kartasi (Super Mukammal Expandable)
// Bosilganda ochiladi: Qarz qo'shish, Jami to'lash va qarzlar tarixi
// Hech qanday so'z bo'linishi yoki xatoliklarsiz!
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/database_providers.dart';
import 'add_debt_dialog.dart';
import 'make_payment_dialog.dart';

class CustomerTile extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerTile({super.key, required this.customer});

  @override
  ConsumerState<CustomerTile> createState() => _CustomerTileState();
}

class _CustomerTileState extends ConsumerState<CustomerTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);

    return StreamBuilder<Customer?>(
      stream: db.customersDao.watchAllCustomers().map(
            (list) => list.where((c) => c.id == widget.customer.id).firstOrNull,
          ),
      initialData: widget.customer,
      builder: (context, snapshot) {
        final customer = snapshot.data ?? widget.customer;
        final hasDebt = customer.totalDebt > 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasDebt
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0),
              width: hasDebt ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Asosiy Mijoz Qatori (Bosh qism) ────────────
              InkWell(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      // Avatar (Qarz bo'lsa qizil, toza bo'lsa yashil)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: hasDebt
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(
                            hasDebt
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            color: hasDebt
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF059669),
                            size: 24,
                          ),
                        ),
                      ),
                      const Gap(12),

                      // Ism va Telefon
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(3),
                            Text(
                              (customer.phone != null &&
                                      customer.phone!.trim().isNotEmpty)
                                  ? customer.phone!
                                  : "Telefon kiritilmagan",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const Gap(10),

                      // Qarz summasi va Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatSum(customer.totalDebt),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: hasDebt
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF059669),
                            ),
                          ),
                          const Gap(3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasDebt
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasDebt ? "QARZDOR" : "TOZA",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: hasDebt
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF059669),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),

                      // Ochish / Yopish ikonkasi
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Kengaytirilgan Qism (Qarzlar va Amallar) ───
              if (_isExpanded) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2 ta Katta Tezkor Tugma: Qarz qo'shish & Jami to'lash
                      Row(
                        children: [
                          // 1. Qarz qo'shish
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      AddDebtDialog(customer: customer),
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded,
                                  size: 16),
                              label: const Text(
                                "Qarz qo'shish",
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                foregroundColor: const Color(0xFF2563EB),
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                      color: Color(0xFFBFDBFE)),
                                ),
                              ),
                            ),
                          ),
                          const Gap(10),

                          // 2. Jami to'lash
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: hasDebt
                                  ? () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => MakePaymentDialog(
                                            customer: customer),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.payments_outlined,
                                  size: 16),
                              label: const Text(
                                "Jami to'lash",
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Gap(14),

                      // Qarzlar tarixi ro'yxati
                      StreamBuilder<List<Debt>>(
                        stream: db.debtsDao.watchDebtsForCustomer(customer.id),
                        builder: (context, debtSnapshot) {
                          final debts = debtSnapshot.data ?? [];

                          if (debts.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  "Hozircha qarz yozuvlari yo'q",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Qarzlar va To'lovlar Tarixi",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  Text(
                                    "${debts.length} ta yozuv",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),

                              ...debts.map((debt) {
                                final isPayment = debt.type == 'payment' || debt.amount < 0;
                                final dateStr = Formatters.dateTime(debt.createdAt);
                                final title = debt.description ?? (isPayment ? "Qarz to'lovi" : "Qarz yozildi");

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isPayment
                                          ? const Color(0xFFA7F3D0)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Nomi va Summasi
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Gap(8),
                                          Text(
                                            isPayment
                                                ? "-${formatSum(debt.amount.abs())}"
                                                : formatSum(debt.amount),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: isPayment
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(4),

                                      // Vaqti va Holati
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (!isPayment)
                                            InkWell(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) =>
                                                      MakePaymentDialog(
                                                    customer: customer,
                                                    initialAmount: debt.amount,
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFEFF6FF),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFBFDBFE)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .credit_card_rounded,
                                                        size: 12,
                                                        color:
                                                            Color(0xFF2563EB)),
                                                    Gap(4),
                                                    Text(
                                                      "To'lash",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            Color(0xFF2563EB),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
