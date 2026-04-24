import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'models.dart';

class DorkCard extends StatefulWidget {
  final Dork dork;
  final bool secili;
  final ValueChanged<bool> onSecim;
  final VoidCallback onTekAc;

  const DorkCard({
    super.key,
    required this.dork,
    required this.secili,
    required this.onSecim,
    required this.onTekAc,
  });

  @override
  State<DorkCard> createState() => _DorkCardState();
}

class _DorkCardState extends State<DorkCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.secili ? 1.0 : 0.0,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(DorkCard old) {
    super.didUpdateWidget(old);
    if (widget.secili != old.secili) {
      widget.secili ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renk = kategoriRenk(widget.dork.kategori);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onSecim(!widget.secili),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: widget.secili
                  ? Color.lerp(kKart, renk.withValues(alpha:0.07), _anim.value)
                  : _hovered
                      ? const Color(0xFF161D2A)
                      : kKart,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                  color: Color.lerp(Colors.transparent, renk, _anim.value)!,
                  width: 3,
                ),
                top: BorderSide(color: kSinirAcik.withValues(alpha:0.4), width: 0.5),
                right: BorderSide(color: kSinirAcik.withValues(alpha:0.4), width: 0.5),
                bottom: BorderSide(color: kSinirAcik.withValues(alpha:0.4), width: 0.5),
              ),
              boxShadow: widget.secili
                  ? [
                      BoxShadow(
                        color: renk.withValues(alpha:0.12 * _anim.value),
                        blurRadius: 16,
                        offset: const Offset(-3, 0),
                      )
                    ]
                  : [],
            ),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Padding(
                  padding: const EdgeInsets.only(top: 1, right: 10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: widget.secili,
                      onChanged: (v) => widget.onSecim(v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),

                // İçerik
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst satır
                      Row(
                        children: [
                          Text(
                            '#${widget.dork.id.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: kMetinCok,
                              fontSize: 11,
                              fontFamily: 'Courier New',
                            ),
                          ),
                          const SizedBox(width: 8),
                          _KategoriBadge(
                              kategori: widget.dork.kategori, renk: renk),
                          const Spacer(),
                          _MiniBtn(
                            icon: Icons.copy_rounded,
                            tooltip: 'Sorguyu kopyala',
                            onTap: () => Clipboard.setData(
                                ClipboardData(text: widget.dork.sorgu)),
                          ),
                          const SizedBox(width: 4),
                          _MiniBtn(
                            icon: Icons.open_in_new_rounded,
                            tooltip: "Google'da aç",
                            renk: kVurgu2,
                            onTap: widget.onTekAc,
                          ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      // Sorgu kutusu (terminal stili)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: kArkaplan,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF1E2840), width: 0.8),
                        ),
                        child: Text(
                          widget.dork.sorgu,
                          style: const TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 12.5,
                            color: kVurgu,
                            height: 1.55,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Açıklama
                      Text(
                        widget.dork.aciklama,
                        style: const TextStyle(
                          color: kMetinSoluk,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 9),

                      // Etiketler
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: widget.dork.etiketler
                            .map((e) => _Etiket(etiket: e))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KategoriBadge extends StatelessWidget {
  final String kategori;
  final Color renk;
  const _KategoriBadge({required this.kategori, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.withValues(alpha:0.35)),
      ),
      child: Text(
        kategori,
        style: TextStyle(
          color: renk,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  final String etiket;
  const _Etiket({required this.etiket});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2035),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        etiket,
        style: const TextStyle(color: kMetinCok, fontSize: 10.5),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color renk;
  final VoidCallback onTap;

  const _MiniBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.renk = kMetinCok,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 15, color: renk),
        ),
      ),
    );
  }
}
