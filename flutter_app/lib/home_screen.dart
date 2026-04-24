import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'models.dart';
import 'api_service.dart';
import 'dork_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  final _hedefCtrl = TextEditingController();
  final _aramaCtrl = TextEditingController();
  final _filetypeCtrl = TextEditingController();
  final _inurlCtrl = TextEditingController();
  final _intitleCtrl = TextEditingController();
  final _intextCtrl = TextEditingController();
  final _beforeCtrl = TextEditingController();
  final _afterCtrl = TextEditingController();

  List<Dork> _tumDorklar = [];
  List<Dork> _filtrelenmis = [];
  final Set<int> _secilenler = {};
  String _secilenKategori = '';
  bool _yukleniyor = true;
  bool _aramaYapiliyor = false;
  bool _filtrelerAcik = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _aramaCtrl.addListener(_filtrele);
    _baslat();
  }

  Future<void> _baslat() async {
    await _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final jsonStr =
          await rootBundle.loadString('assets/backend/dorklar_45.json');
      final liste = jsonDecode(jsonStr) as List<dynamic>;
      final dorklar =
          liste.map((e) => Dork.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() {
        _tumDorklar = dorklar;
        _yukleniyor = false;
      });
      _filtrele();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Dork verisi okunamadı: $e';
        _yukleniyor = false;
      });
    }
  }

  void _filtrele() {
    final arama = _aramaCtrl.text.toLowerCase().trim();
    setState(() {
      _filtrelenmis = _tumDorklar.where((d) {
        if (_secilenKategori.isNotEmpty && d.kategori != _secilenKategori) {
          return false;
        }
        if (arama.isEmpty) return true;
        return d.sorgu.toLowerCase().contains(arama) ||
            d.aciklama.toLowerCase().contains(arama) ||
            d.etiketler.any((e) => e.toLowerCase().contains(arama)) ||
            d.kategori.toLowerCase().contains(arama);
      }).toList();
    });
  }

  void _kategoriSec(String kat) {
    setState(() => _secilenKategori = kat);
    _filtrele();
  }

  void _tumunuSec() {
    setState(() {
      for (final d in _filtrelenmis) {
        _secilenler.add(d.id);
      }
    });
  }

  void _secimTemizle() {
    setState(() => _secilenler.clear());
  }

  /// filtre
  bool get _herhangiFiltre => [
        _filetypeCtrl,
        _inurlCtrl,
        _intitleCtrl,
        _intextCtrl,
        _beforeCtrl,
        _afterCtrl,
      ].any((c) => c.text.trim().isNotEmpty);

  String _dorkUret(Dork dork, String hedef) {
    final temizHedef = hedef.trim();
    if (temizHedef.isEmpty) return dork.sorgu;

    if (dork.sorgu.contains('example.com')) {
      return dork.sorgu.replaceAll('example.com', temizHedef);
    }

    return 'site:$temizHedef ${dork.sorgu}';
  }

  String _filtreEkle(String sorgu) {
    final parcalar = <String>[];
    if (sorgu.trim().isNotEmpty) parcalar.add(sorgu.trim());

    final ft = _filetypeCtrl.text.trim();
    final iu = _inurlCtrl.text.trim();
    final it = _intitleCtrl.text.trim();
    final ix = _intextCtrl.text.trim();
    final bf = _beforeCtrl.text.trim();
    final af = _afterCtrl.text.trim();

    if (ft.isNotEmpty) {
      final tipler = ft
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (tipler.length == 1) {
        parcalar.add('filetype:${tipler.first}');
      } else if (tipler.isNotEmpty) {
        parcalar.add('(${tipler.map((t) => 'filetype:$t').join(' OR ')})');
      }
    }

    if (iu.isNotEmpty)
      parcalar.add(iu.contains(' ') ? 'inurl:"$iu"' : 'inurl:$iu');
    if (it.isNotEmpty)
      parcalar.add(it.contains(' ') ? 'intitle:"$it"' : 'intitle:$it');
    if (ix.isNotEmpty)
      parcalar.add(ix.contains(' ') ? 'intext:"$ix"' : 'intext:$ix');
    if (bf.isNotEmpty) parcalar.add('before:$bf');
    if (af.isNotEmpty) parcalar.add('after:$af');

    return parcalar.join(' ');
  }

  Future<void> _googleAra() async {
    if (_aramaYapiliyor) return;
    final dorkVar = _secilenler.isNotEmpty;
    final filtreVar = _herhangiFiltre;
    if (!dorkVar && !filtreVar) return;

    setState(() => _aramaYapiliyor = true);
    try {
      final hedef = _hedefCtrl.text.trim();
      String birlesikSorgu;

      if (!dorkVar) {
        final base = hedef.isNotEmpty ? 'site:$hedef' : '';
        birlesikSorgu = _filtreEkle(base);
      } else {
        final parcalar = _tumDorklar
            .where((d) => _secilenler.contains(d.id))
            .map((d) => _filtreEkle(_dorkUret(d, hedef)))
            .where((s) => s.trim().isNotEmpty)
            .toList();
        birlesikSorgu = parcalar.join(' OR ');
      }

      if (birlesikSorgu.trim().isEmpty) {
        throw Exception('Arama sorgusu bos');
      }

      await _api.googleAra(sorgu: birlesikSorgu);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: kHata,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _aramaYapiliyor = false);
    }
  }

  Future<void> _tekDorkAc(Dork dork) async {
    try {
      final sorgu = _filtreEkle(_dorkUret(dork, _hedefCtrl.text.trim()));
      if (sorgu.trim().isEmpty) return;
      await _api.googleAra(sorgu: sorgu);
    } catch (_) {}
  }

  @override
  void dispose() {
    _hedefCtrl.dispose();
    _aramaCtrl.dispose();
    _filetypeCtrl.dispose();
    _inurlCtrl.dispose();
    _intitleCtrl.dispose();
    _intextCtrl.dispose();
    _beforeCtrl.dispose();
    _afterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kArkaplan,
      body: Column(
        children: [
          _buildHeader(),
          _buildAkordeon(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }



  Widget _buildAkordeon() {
    // Aktif filtre sayısı badge
    final aktifSayi = [
      _filetypeCtrl,
      _inurlCtrl,
      _intitleCtrl,
      _intextCtrl,
      _beforeCtrl,
      _afterCtrl,
    ].where((c) => c.text.trim().isNotEmpty).length;

    return Container(
      decoration: const BoxDecoration(
        color: kYuzey,
        border: Border(bottom: BorderSide(color: kSinir)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Toggle bar
          InkWell(
            onTap: () => setState(() => _filtrelerAcik = !_filtrelerAcik),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _filtrelerAcik ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: kMetinCok, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GELİŞMİŞ FİLTRELER',
                    style: TextStyle(
                      color: kMetinCok,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (aktifSayi > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: kVurgu.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: kVurgu.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$aktifSayi aktif',
                        style: const TextStyle(
                          color: kVurgu,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (aktifSayi > 0)
                    TextButton(
                      onPressed: () => setState(() {
                        _filetypeCtrl.clear();
                        _inurlCtrl.clear();
                        _intitleCtrl.clear();
                        _intextCtrl.clear();
                        _beforeCtrl.clear();
                        _afterCtrl.clear();
                      }),
                      style: TextButton.styleFrom(
                        foregroundColor: kHata,
                        textStyle: const TextStyle(fontSize: 11),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Filtreleri Temizle'),
                    ),
                ],
              ),
            ),
          ),


          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOut,
            crossFadeState: _filtrelerAcik
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FiltreAlani(
                    ctrl: _filetypeCtrl,
                    label: 'filetype:',
                    hint: 'pdf, sql, env...',
                    tooltip:
                        'Sadece bu uzantıdaki dosyaları getirir.\nÖrn: pdf → filetype:pdf\nÖrn: env → filetype:env',
                    icon: Icons.insert_drive_file_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  _FiltreAlani(
                    ctrl: _inurlCtrl,
                    label: 'inurl:',
                    hint: 'admin, login...',
                    tooltip:
                        'Sayfanın URL\'sinde bu kelimeyi arar.\nÖrn: admin → yalnızca URL\'de "admin" geçen sayfalar\nÖrn: backup → .../backup/... yolundaki sayfalar',
                    icon: Icons.link_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  _FiltreAlani(
                    ctrl: _intitleCtrl,
                    label: 'intitle:',
                    hint: 'login panel...',
                    tooltip:
                        'Sayfanın <title> başlığında bu metni arar.\nÖrn: "login panel" → başlığı tam bu olan sayfalar\nURL veya içerikle ilgisi yok, sadece sekme başlığı.',
                    icon: Icons.title_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  _FiltreAlani(
                    ctrl: _intextCtrl,
                    label: 'intext:',
                    hint: 'password, key...',
                    tooltip:
                        'Sayfanın görünür içeriğinde (body) bu metni arar.\nÖrn: password → sayfada "password" kelimesi geçenler\nURL veya başlıkla ilgisi yok, sadece sayfa içeriği.',
                    icon: Icons.article_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  _FiltreAlani(
                    ctrl: _beforeCtrl,
                    label: 'before:',
                    hint: '2023-01-01',
                    tooltip:
                        'Bu tarihten önce Google\'a dizinlenmiş sayfaları getirir.\nBiçim: YYYY-MM-DD\nOSINT\'te eski sızıntıları, arşivleri bulmak için kullanılır.',
                    icon: Icons.calendar_today_rounded,
                    width: 150,
                    onChanged: (_) => setState(() {}),
                  ),
                  _FiltreAlani(
                    ctrl: _afterCtrl,
                    label: 'after:',
                    hint: '2024-01-01',
                    tooltip:
                        'Bu tarihten sonra Google\'a dizinlenmiş sayfaları getirir.\nBiçim: YYYY-MM-DD\nYeni açılan panelleri, güncel belgeleri bulmak için kullanılır.',
                    icon: Icons.calendar_month_rounded,
                    width: 150,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: kYuzey,
        border: Border(bottom: BorderSide(color: kSinir)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Logo + başlık
          const Icon(Icons.radar_rounded, color: kVurgu, size: 20),
          const SizedBox(width: 10),
          const Text(
            'HEDEF DORKING',
            style: TextStyle(
              color: kVurgu,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              fontFamily: 'Courier New',
            ),
          ),
          const Spacer(),

          // Hedef input
          SizedBox(
            width: 300,
            child: TextField(
              controller: _hedefCtrl,
              style: const TextStyle(
                  color: kMetin, fontSize: 13, fontFamily: 'Courier New'),
              decoration: InputDecoration(
                hintText: 'hedef: example.com',
                hintStyle: const TextStyle(
                    color: kMetinCok, fontSize: 13, fontFamily: 'Courier New'),
                prefixIcon: const Icon(Icons.language_rounded,
                    color: kMetinCok, size: 16),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: kKart,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kSinirAcik, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kSinirAcik, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kVurgu, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Yenile
          Tooltip(
            message: 'Dorkları yenile',
            child: IconButton(
              onPressed: _baslat,
              icon:
                  const Icon(Icons.refresh_rounded, color: kMetinCok, size: 18),
              splashRadius: 18,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSidebar() {
    // Kategori başına dork sayısı
    final sayilar = <String, int>{};
    for (final d in _tumDorklar) {
      sayilar[d.kategori] = (sayilar[d.kategori] ?? 0) + 1;
    }

    return Container(
      width: 215,
      decoration: const BoxDecoration(
        color: kYuzey,
        border: Border(right: BorderSide(color: kSinir)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text(
              'KATEGORİLER',
              style: TextStyle(
                color: kMetinCok,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          _SidebarItem(
            label: 'Tümü',
            sayi: _tumDorklar.length,
            secili: _secilenKategori.isEmpty,
            renk: kMetinSoluk,
            onTap: () => _kategoriSec(''),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Divider(color: kSinir, height: 1),
          ),
          ...kKategoriRenkleri.entries.map((e) {
            final sayi = sayilar[e.key] ?? 0;
            if (sayi == 0) return const SizedBox.shrink();
            return _SidebarItem(
              label: e.key,
              sayi: sayi,
              secili: _secilenKategori == e.key,
              renk: e.value,
              onTap: () => _kategoriSec(e.key),
            );
          }),
        ],
      ),
    );
  }

  // ─ CONTENT

  Widget _buildContent() {
    if (_yukleniyor) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: kVurgu, strokeWidth: 2),
            ),
            SizedBox(height: 14),
            Text('Dorklar yükleniyor...',
                style: TextStyle(color: kMetinCok, fontSize: 13)),
          ],
        ),
      );
    }

    if (_hata != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: kHata, size: 44),
            const SizedBox(height: 16),
            Text(
              _hata!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kMetinSoluk, fontSize: 13, height: 1.7),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _baslat,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2035),
                foregroundColor: kVurgu,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Araç çubuğu (arama + butonlar)
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kSinir)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aramaCtrl,
                  style: const TextStyle(color: kMetin, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Dork ara: sql, kamera, password...',
                    hintStyle: const TextStyle(color: kMetinCok, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: kMetinCok, size: 16),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    filled: true,
                    fillColor: kKart,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: kSinirAcik, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: kSinirAcik, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kVurgu2, width: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_filtrelenmis.length} dork',
                style: const TextStyle(color: kMetinCok, fontSize: 12),
              ),
              const SizedBox(width: 10),
              _TextBtn(label: 'Tümünü Seç', renk: kVurgu2, onTap: _tumunuSec),
              const SizedBox(width: 2),
              _TextBtn(label: 'Temizle', renk: kMetinCok, onTap: _secimTemizle),
            ],
          ),
        ),

        // Dork listesi
        Expanded(
          child: _filtrelenmis.isEmpty
              ? const Center(
                  child: Text('Sonuç bulunamadı',
                      style: TextStyle(color: kMetinCok, fontSize: 13)),
                )
              : Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filtrelenmis.length,
                    itemBuilder: (ctx, i) {
                      final dork = _filtrelenmis[i];
                      return DorkCard(
                        key: ValueKey(dork.id),
                        dork: dork,
                        secili: _secilenler.contains(dork.id),
                        onSecim: (v) => setState(() {
                          v
                              ? _secilenler.add(dork.id)
                              : _secilenler.remove(dork.id);
                        }),
                        onTekAc: () => _tekDorkAc(dork),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }


  Widget _buildBottomBar() {
    final sayi = _secilenler.length;
    final goster = sayi > 0 || _herhangiFiltre;

    // Badge etiketi
    String badgeMetin;
    if (sayi > 0 && _herhangiFiltre) {
      badgeMetin = '$sayi dork + filtre';
    } else if (sayi > 0) {
      badgeMetin = '$sayi dork seçili';
    } else {
      badgeMetin = 'Filtre araması';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: goster ? 58 : 0,
      color: kYuzey,
      child: goster
          ? Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kSinir)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Seçili badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: kVurgu.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kVurgu.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      badgeMetin,
                      style: const TextStyle(
                        color: kVurgu,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _hedefCtrl.text.trim().isEmpty
                        ? 'hedef girilmedi'
                        : '→ ${_hedefCtrl.text.trim()}',
                    style: const TextStyle(color: kMetinCok, fontSize: 12),
                  ),
                  const Spacer(),

                  // ARA butonu
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _aramaYapiliyor ? null : _googleAra,
                      icon: _aramaYapiliyor
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kArkaplan,
                              ),
                            )
                          : const Icon(Icons.open_in_browser_rounded, size: 17),
                      label: Text(
                          _aramaYapiliyor ? 'Açılıyor...' : "GOOGLE'DA ARA"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kVurgu,
                        foregroundColor: kArkaplan,
                        disabledBackgroundColor: kVurgu.withValues(alpha: 0.4),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}


class _SidebarItem extends StatefulWidget {
  final String label;
  final int sayi;
  final bool secili;
  final Color renk;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.sayi,
    required this.secili,
    required this.renk,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.secili
                ? widget.renk.withValues(alpha: 0.1)
                : _hovered
                    ? const Color(0xFF161B22)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.secili
                ? Border.all(color: widget.renk.withValues(alpha: 0.22))
                : null,
          ),
          child: Row(
            children: [
              // Renkli nokta
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.secili
                      ? widget.renk
                      : widget.renk.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.secili ? widget.renk : kMetinSoluk,
                    fontSize: 13,
                    fontWeight:
                        widget.secili ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              // Sayı badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2035),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.sayi}',
                  style: const TextStyle(color: kMetinCok, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final Color renk;
  final VoidCallback onTap;

  const _TextBtn(
      {required this.label, required this.renk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: renk,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}


class _FiltreAlani extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final String tooltip;
  final IconData icon;
  final double width;
  final ValueChanged<String> onChanged;

  const _FiltreAlani({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.tooltip,
    required this.icon,
    required this.onChanged,
    this.width = 170,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + tooltip ikonu
          Tooltip(
            message: tooltip,
            preferBelow: false,
            textStyle: const TextStyle(
              color: kMetin,
              fontSize: 12,
              height: 1.6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2035),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kSinirAcik),
            ),
            child: Row(
              children: [
                Icon(icon, size: 12, color: kMetinCok),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: kMetinSoluk,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Courier New',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.help_outline_rounded,
                    size: 11, color: kMetinCok),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // Input
          TextField(
            controller: ctrl,
            onChanged: onChanged,
            style: const TextStyle(
              color: kMetin,
              fontSize: 12.5,
              fontFamily: 'Courier New',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: kMetinCok,
                fontSize: 12,
                fontFamily: 'Courier New',
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: kArkaplan,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: kSinirAcik, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: kSinirAcik, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: kVurgu2, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
