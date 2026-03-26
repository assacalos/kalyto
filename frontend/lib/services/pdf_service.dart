import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/utils/tva_rates_ci.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/services/company_service.dart';

/// Clé de stockage du NINEA entreprise (paramètres société).
const String _kCompanyNineaStorageKey = 'company_ninea';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  /// Convertit une valeur dynamique (String, int, double, null) en double pour éviter les erreurs de cast.
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Cache pour les images
  pw.MemoryImage? _logoImage;
  pw.MemoryImage? _signatureImage;
  bool _imagesLoaded = false;

  // Charger logo et signature : d'abord API (société courante), sinon assets par défaut (logo_test / signature_test)
  // pour une bonne visibilité avec des dimensions adaptées.
  Future<void> _loadImages({bool forceReload = false, int? companyId}) async {
    final cid = companyId ?? CompanyService.getCurrentCompanyId();
    if (!forceReload && _imagesLoaded && (_logoImage != null || _signatureImage != null)) {
      if (_logoImage != null && _signatureImage != null) return;
    }

    if (forceReload || _logoImage == null || _signatureImage == null) {
      _logoImage = null;
      _signatureImage = null;
      _imagesLoaded = false;
    }

    try {
      // Logo : API société courante, sinon asset par défaut (bonnes dimensions dans l'en-tête)
      if (_logoImage == null) {
        final apiLogo = await CompanyService.getCompanyLogoBytes(cid);
        if (apiLogo != null && apiLogo.isNotEmpty) {
          _logoImage = pw.MemoryImage(apiLogo);
        } else {
          try {
            final bytes = await rootBundle.load('assets/images/logo_pdf_default.png');
            _logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
          } catch (_) {
            _logoImage = null;
          }
        }
      }

      // Signature : API société courante, sinon asset par défaut (bloc coordonnées, dimensions adaptées)
      if (_signatureImage == null) {
        final apiSignature = await CompanyService.getCompanySignatureBytes(cid);
        if (apiSignature != null && apiSignature.isNotEmpty) {
          _signatureImage = pw.MemoryImage(apiSignature);
        } else {
          try {
            final bytes = await rootBundle.load('assets/images/signature_pdf_default.png');
            _signatureImage = pw.MemoryImage(bytes.buffer.asUint8List());
          } catch (_) {
            _signatureImage = null;
          }
        }
      }

      _imagesLoaded = true;
    } catch (e) {
      print('⚠️ Impossible de charger les images PDF: $e');
      _logoImage = null;
      _signatureImage = null;
      _imagesLoaded = true;
    }
  }

  // Générer un PDF de devis
  Future<void> generateDevisPdf({
    required Map<String, dynamic> devis,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      final companyNinea = GetStorage().read<String>(_kCompanyNineaStorageKey)?.trim();
      final ref = (devis['reference'] ?? 'N/A').toString();
      pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 35, vertical: 28),
          build: (pw.Context context) {
            return [
              _buildHeader(
                'DEVIS',
                ref,
                titre: devis['titre']?.toString(),
                compact: true,
                logoSizeOverride: 140.0,
                companyNinea: companyNinea?.isNotEmpty == true ? companyNinea : null,
              ),
              pw.SizedBox(height: 12),
              _buildClientInfo(client, compact: true),
              pw.SizedBox(height: 12),
              ..._buildItemsTableWithPagination(items, compact: true),
              pw.SizedBox(height: 12),
              _buildAdditionalInfo(devis, compact: true),
              pw.SizedBox(height: 12),
              _buildTotals(devis, compact: true),
              pw.SizedBox(height: 12),
              _buildPaymentConditions(devis, compact: true),
              _buildLegalMention('DEVIS'),
              pw.SizedBox(height: 20),
              _buildSignature(compact: true, signatureSizeOverride: 220.0, signatureHeightOverride: 90.0),
            ];
          },
          footer: (pw.Context context) {
            if (context.pageNumber == context.pagesCount) {
              return _buildFooter(commercial, companyNinea: companyNinea);
            }
            return pw.SizedBox.shrink();
          },
          maxPages: 10,
        ),
      );

      final reference = devis['reference']?.toString() ?? 'N/A';
      await _saveAndOpenPdf(pdf, 'devis_${reference}.pdf');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF devis: $e');
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  // Générer un PDF de bordereau (structure comme devis : infos entreprise en bas, signature)
  Future<void> generateBordereauPdf({
    required Map<String, dynamic> bordereau,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 35, vertical: 28),
          build: (pw.Context context) {
            return [
              _buildHeader(
                'BORDEREAU',
                (bordereau['reference'] ?? 'N/A').toString(),
                titre: bordereau['titre']?.toString(),
              ),
              pw.SizedBox(height: 20),
              _buildClientInfo(client),
              pw.SizedBox(height: 20),
              _buildBordereauItemsTable([
                ...items,
                {'reference': '', 'designation': 'Assistance et formation', 'quantite': '-'},
              ]),
              pw.SizedBox(height: 12),
              _buildBordereauExtraInfoInline(bordereau),
              pw.SizedBox(height: 20),
              _buildSignature(),
            ];
          },
          footer: (pw.Context context) {
            if (context.pageNumber == context.pagesCount) {
              return _buildFooter(commercial);
            }
            return pw.SizedBox.shrink();
          },
          maxPages: 10,
        ),
      );

      await _saveAndOpenPdf(
        pdf,
        'bordereau_${bordereau['reference'] ?? 'N/A'}.pdf',
      );
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF bordereau: $e');
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  // Générer un PDF de bon de commande (structure comme devis/bordereau : infos entreprise en bas, signature)
  Future<void> generateBonCommandePdf({
    required Map<String, dynamic> bonCommande,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> fournisseur,
    Map<String, dynamic>?
    client, // Optionnel pour les bons de commande entreprise
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      pdf = pw.Document();

      final tableItems = [
        ...items,
        {'reference': '', 'ref': '', 'designation': 'Assistance et formation', 'quantite': '-', 'prix_unitaire': 0.0, 'montant_total': 0.0},
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 35, vertical: 28),
          build: (pw.Context context) {
            return [
              _buildHeader(
                'BON DE COMMANDE',
                (bonCommande['reference'] ?? 'N/A').toString(),
                titre: bonCommande['titre']?.toString(),
              ),
              pw.SizedBox(height: 20),
              client != null
                  ? _buildClientInfo(client)
                  : _buildSupplierInfo(fournisseur),
              pw.SizedBox(height: 20),
              _buildItemsTable(tableItems),
              pw.SizedBox(height: 12),
              _buildBonCommandeExtraInfoInline(bonCommande),
              pw.SizedBox(height: 20),
              _buildTotals(bonCommande),
              pw.SizedBox(height: 20),
              _buildSignature(),
            ];
          },
          footer: (pw.Context context) {
            if (context.pageNumber == context.pagesCount) {
              return _buildFooter(null);
            }
            return pw.SizedBox.shrink();
          },
          maxPages: 10,
        ),
      );

      final reference = bonCommande['reference']?.toString() ?? 'N/A';
      await _saveAndOpenPdf(pdf, 'bon_commande_${reference}.pdf');
    } catch (e) {
      throw Exception(
        'Erreur lors de la génération du PDF bon de commande: $e',
      );
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  // Générer un PDF de facture
  Future<void> generateFacturePdf({
    required Map<String, dynamic> facture,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      final companyNinea = GetStorage().read<String>(_kCompanyNineaStorageKey)?.trim();
      final ref = (facture['reference'] ?? 'N/A').toString();
      pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  'FACTURE',
                  ref,
                  companyNinea: companyNinea?.isNotEmpty == true ? companyNinea : null,
                ),
                pw.SizedBox(height: 20),
                _buildClientInfo(client),
                pw.SizedBox(height: 20),
                _buildItemsTable(items),
                pw.SizedBox(height: 20),
                _buildTotals(facture),
                _buildLegalMention('FACTURE'),
                pw.SizedBox(height: 30),
                _buildFooter(commercial, companyNinea: companyNinea),
              ],
            );
          },
        ),
      );

      await _saveAndOpenPdf(
        pdf,
        'facture_${facture['reference'] ?? 'N/A'}.pdf',
      );
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF facture: $e');
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  // Générer un PDF de paiement
  Future<void> generatePaiementPdf({
    required Map<String, dynamic> paiement,
    required Map<String, dynamic> facture,
    required Map<String, dynamic> client,
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  'REÇU DE PAIEMENT',
                  (paiement['reference'] ?? 'N/A').toString(),
                ),
                pw.SizedBox(height: 20),
                _buildClientInfo(client),
                pw.SizedBox(height: 20),
                _buildPaymentInfo(paiement, facture),
                pw.SizedBox(height: 30),
                _buildFooter(null),
              ],
            );
          },
        ),
      );

      await _saveAndOpenPdf(
        pdf,
        'paiement_${paiement['reference'] ?? 'N/A'}.pdf',
      );
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF paiement: $e');
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  /// Bulletin de paie PDF (style ivoirien, FCFA).
  /// Données déjà calculées par l'API : base, primes, déductions, CNPS, IR, net.
  Future<void> generateBulletinPaiePdf(Salary salary) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      final companyNinea =
          GetStorage().read<String>(_kCompanyNineaStorageKey)?.trim();
      final ref = salary.id != null
          ? 'BUL-${salary.year ?? ''}-${salary.month ?? ''}-${salary.id}'
          : 'BUL-${salary.periodText.replaceAll(' ', '-')}';
      pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 35, vertical: 28),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  'BULLETIN DE PAIE',
                  ref,
                  companyNinea: companyNinea?.isNotEmpty == true
                      ? companyNinea
                      : null,
                ),
                pw.SizedBox(height: 20),
                _buildBulletinEmployeInfo(salary),
                pw.SizedBox(height: 20),
                _buildBulletinTotals(salary),
                pw.SizedBox(height: 24),
                _buildLegalMention('BULLETIN DE PAIE'),
                pw.SizedBox(height: 20),
                _buildFooter(null, companyNinea: companyNinea),
              ],
            );
          },
        ),
      );

      final fileName =
          'bulletin_paie_${salary.employeeName ?? 'employe'}_${salary.month ?? ''}_${salary.year ?? ''}.pdf'
              .replaceAll(RegExp(r'[^\w\-.]'), '_');
      await _saveAndOpenPdf(pdf, fileName);
    } catch (e) {
      throw Exception(
          'Erreur lors de la génération du bulletin de paie: $e');
    } finally {
      pdf = null;
    }
  }

  pw.Widget _buildBulletinEmployeInfo(Salary salary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EMPLOYÉ',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            salary.employeeName ?? '—',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          if (salary.employeeEmail != null &&
              salary.employeeEmail!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              salary.employeeEmail!,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            'Période : ${salary.periodText}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.normal,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBulletinTotals(Salary salary) {
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0);
    final base = salary.baseSalary;
    final primes = salary.totalAllowances ?? salary.bonus;
    final brut = salary.grossSalary ?? (base + primes);
    final cnpsSalarie = salary.totalSocialSecurity ?? 0.0;
    final impotRevenu = salary.totalTaxes ?? 0.0;
    final autresDeductions = salary.totalDeductions ?? salary.deductions;
    final net = salary.netSalary;

    double autres = autresDeductions;
    if (cnpsSalarie > 0 || impotRevenu > 0) {
      final deduits = cnpsSalarie + impotRevenu;
      if (autres <= 0 && deduits > 0) {
        autres = 0;
      }
    }

    pw.Widget row(String label, double amount, {bool isBold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              '${fmt.format(amount)} FCFA',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    final lines = <pw.Widget>[
      row('Salaire de base', base),
      if (primes > 0) row('Primes / Avantages', primes),
      row('Salaire brut', brut, isBold: true),
    ];
    if ((salary.cnpsEmployeur ?? 0) > 0) {
      lines.add(row('Cotisation CNPS - Part employeur', salary.cnpsEmployeur!));
    }
    if (cnpsSalarie > 0) {
      lines.add(row('Cotisation CNPS - Part salarié', cnpsSalarie));
    }
    if (impotRevenu > 0) {
      lines.add(row('Impôt sur le revenu', impotRevenu));
    }
    if (autres > 0) {
      lines.add(row('Autres déductions', autres));
    }
    lines.add(row('Net à payer', net, isBold: true));

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'DÉTAIL DU SALAIRE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...lines,
        ],
      ),
    );
  }

  // Construire l'en-tête du document
  /// [logoSizeOverride] : si fourni, utilise cette taille pour le logo (ex: aligner devis sur bordereau).
  /// [companyNinea] : NINEA de l'entreprise (affiché si renseigné).
  pw.Widget _buildHeader(
    String documentType,
    String reference, {
    String? titre,
    bool compact = false,
    double? logoSizeOverride,
    String? companyNinea,
  }) {
    final padding = compact ? 12.0 : 20.0;
    final logoSize = logoSizeOverride ?? (compact ? 72.0 : 140.0);
    final titleSpacing = compact ? 6.0 : 10.0;
    final refFontSize = compact ? 16.0 : 22.0;
    final refLabelFontSize = compact ? 10.0 : 12.0;
    final dateFontSize = compact ? 10.0 : 12.0;
    final titreSpacing = compact ? 8.0 : 15.0;
    final titreFontSize = compact ? 12.0 : 16.0;
    final refDisplay = reference.trim().isNotEmpty ? reference : 'N/A';
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (_logoImage != null) ...[
                    pw.Image(
                      _logoImage!,
                      width: logoSize,
                      height: logoSize,
                      fit: pw.BoxFit.contain,
                    ),
                    pw.SizedBox(height: titleSpacing),
                  ],
                  pw.Text(
                    documentType,
                    style: pw.TextStyle(
                      fontSize: refLabelFontSize,
                      fontWeight: pw.FontWeight.normal,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'N° $refDisplay',
                    style: pw.TextStyle(
                      fontSize: refFontSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  if (companyNinea != null &&
                      companyNinea.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'NINEA entreprise : $companyNinea',
                      style: pw.TextStyle(
                        fontSize: refLabelFontSize,
                        color: PdfColors.blue600,
                      ),
                    ),
                  ],
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: dateFontSize),
                  ),
                ],
              ),
            ],
          ),
          if (titre != null && titre.isNotEmpty) ...[
            pw.SizedBox(height: titreSpacing),
            pw.Text(
              titre,
              style: pw.TextStyle(
                fontSize: titreFontSize,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Construire les informations client
  pw.Widget _buildClientInfo(Map<String, dynamic> client,
      {bool compact = false}) {
    final hasNomEntreprise =
        client['nom_entreprise'] != null &&
        client['nom_entreprise'].toString().isNotEmpty;
    final hasNumeroContribuable =
        client['numero_contribuable'] != null &&
        client['numero_contribuable'].toString().isNotEmpty;
    final hasNinea =
        client['ninea'] != null && client['ninea'].toString().trim().isNotEmpty;
    final hasAdresse =
        client['adresse'] != null && client['adresse'].toString().isNotEmpty;

    if (!hasNomEntreprise && !hasNumeroContribuable && !hasNinea && !hasAdresse) {
      return pw.SizedBox.shrink();
    }

    final padding = compact ? 10.0 : 15.0;
    final nomFontSize = compact ? 12.0 : 16.0;
    final smallFontSize = compact ? 9.0 : 12.0;
    final spacing1 = compact ? 4.0 : 8.0;
    final spacing2 = compact ? 3.0 : 5.0;

    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.SizedBox.shrink(),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (hasNomEntreprise) ...[
                  pw.Text(
                    '${client['nom_entreprise']}',
                    style: pw.TextStyle(
                      fontSize: nomFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                  if (hasNumeroContribuable || hasAdresse)
                    pw.SizedBox(height: spacing1),
                ],
                if (hasNumeroContribuable) ...[
                  pw.Text(
                    'N° Contribuable: ${client['numero_contribuable']}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: smallFontSize),
                  ),
                  if (hasNinea || hasAdresse) pw.SizedBox(height: spacing2),
                ],
                if (hasNinea) ...[
                  pw.Text(
                    'NINEA: ${client['ninea']}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: smallFontSize),
                  ),
                  if (hasAdresse) pw.SizedBox(height: spacing2),
                ],
                if (hasAdresse) ...[
                  pw.Text(
                    '${client['adresse']}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: smallFontSize),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construire les informations fournisseur
  pw.Widget _buildSupplierInfo(Map<String, dynamic> fournisseur) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS FOURNISSEUR',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Nom: ${fournisseur['nom'] ?? 'Non spécifié'}'),
          if (fournisseur['email'] != null &&
              fournisseur['email'].toString().isNotEmpty)
            pw.Text('Email: ${fournisseur['email']}'),
          if (fournisseur['contact'] != null &&
              fournisseur['contact'].toString().isNotEmpty)
            pw.Text('Contact: ${fournisseur['contact']}'),
          if (fournisseur['adresse'] != null &&
              fournisseur['adresse'].toString().isNotEmpty)
            pw.Text('Adresse: ${fournisseur['adresse']}'),
        ],
      ),
    );
  }

  // Construire le tableau des articles avec pagination intelligente
  List<pw.Widget> _buildItemsTableWithPagination(
    List<Map<String, dynamic>> items, {
    bool compact = false,
  }) {
    if (items.isEmpty) {
      return [
        pw.Container(
          padding: pw.EdgeInsets.all(compact ? 12 : 20),
          child: pw.Text(
            'Aucun article dans ce devis',
            style: pw.TextStyle(
              fontSize: compact ? 10 : 12,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ];
    }

    const int maxItemsPerPage = 5;
    final List<pw.Widget> tables = [];

    if (items.length <= maxItemsPerPage) {
      tables.add(_buildSingleItemsTable(items, showHeader: true, compact: compact));
      return tables;
    }

    int currentIndex = 0;
    bool isFirstPage = true;

    while (currentIndex < items.length) {
      int remainingItems = items.length - currentIndex;
      int itemsForThisPage =
          remainingItems <= maxItemsPerPage ? remainingItems : maxItemsPerPage;
      final pageItems = items.sublist(
        currentIndex,
        currentIndex + itemsForThisPage,
      );
      tables.add(_buildSingleItemsTable(pageItems,
          showHeader: isFirstPage, compact: compact));
      if (isFirstPage) isFirstPage = false;
      currentIndex += itemsForThisPage;
    }

    return tables;
  }

  // Construire un tableau simple avec les items donnés
  pw.Widget _buildSingleItemsTable(
    List<Map<String, dynamic>> items, {
    bool showHeader = true,
    bool compact = false,
  }) {
    final cellPadding = compact ? 5.0 : 8.0;
    final cellFontSize = compact ? 9.0 : 12.0;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        if (showHeader)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue100),
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  'Référence',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: cellFontSize),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  'Désignation',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: cellFontSize),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  'Qté',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: cellFontSize),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  'Prix U.',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: cellFontSize),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: cellFontSize),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ...items.map(
          (item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  (item['reference'] ?? item['ref'])?.toString() ?? '',
                  style: pw.TextStyle(fontSize: cellFontSize),
                  maxLines: compact ? 2 : null,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  item['designation']?.toString() ?? '',
                  style: pw.TextStyle(fontSize: cellFontSize),
                  maxLines: compact ? 2 : null,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  '${item['quantite'] ?? 0}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: cellFontSize),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(_safeDouble(item['prix_unitaire']))} FCFA',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: cellFontSize),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(cellPadding),
                child: pw.Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(_safeDouble(item['montant_total']))} FCFA',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: cellFontSize),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Construire le tableau des articles (méthode de compatibilité)
  pw.Widget _buildItemsTable(List<Map<String, dynamic>> items) {
    final tables = _buildItemsTableWithPagination(items);
    // Si un seul tableau, le retourner directement
    if (tables.length == 1) {
      return tables[0];
    }
    // Sinon, retourner une colonne avec tous les tableaux
    return pw.Column(children: tables);
  }

  // Tableau des articles du bordereau : Référence, Désignation, Quantité
  pw.Widget _buildBordereauItemsTable(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text(
          'Aucun article dans ce bordereau',
          style: pw.TextStyle(
            fontSize: 12,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey600,
          ),
        ),
      );
    }
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Référence',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Désignation',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Quantité',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
        ...items.map(
          (item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item['reference']?.toString() ?? '',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item['designation']?.toString() ?? '',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${item['quantite'] ?? 0}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Lignes après le tableau du bordereau (sans cadre) : Date de livraison, Délai de garantie
  pw.Widget _buildBordereauExtraInfoInline(Map<String, dynamic> bordereau) {
    final dateLivraison = bordereau['date_livraison'];
    final garantie = bordereau['garantie']?.toString();
    String formatDate(dynamic v) {
      if (v == null) return '';
      if (v is DateTime) return DateFormat('dd/MM/yyyy').format(v);
      if (v is String) {
        try {
          return DateFormat('dd/MM/yyyy').format(DateTime.parse(v));
        } catch (_) {
          return v;
        }
      }
      return '';
    }
    final dateLivraisonStr = formatDate(dateLivraison);
    final hasGarantie = garantie != null && garantie.isNotEmpty;
    if (dateLivraisonStr.isEmpty && !hasGarantie) {
      return pw.SizedBox.shrink();
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (dateLivraisonStr.isNotEmpty)
          pw.Text(
            'Date de livraison : $dateLivraisonStr',
            style: const pw.TextStyle(fontSize: 12),
          ),
        if (dateLivraisonStr.isNotEmpty && hasGarantie) pw.SizedBox(height: 6),
        if (hasGarantie)
          pw.Text(
            'Délai de garantie : $garantie',
            style: const pw.TextStyle(fontSize: 12),
          ),
      ],
    );
  }

  // Lignes après le tableau du bon de commande : Délai de livraison, Conditions de paiement
  pw.Widget _buildBonCommandeExtraInfoInline(Map<String, dynamic> bonCommande) {
    final delaiLivraison = bonCommande['delai_livraison'];
    final conditionsPaiement = bonCommande['conditions_paiement']?.toString();
    final hasDelai = delaiLivraison != null &&
        (delaiLivraison is int ? delaiLivraison > 0 : delaiLivraison.toString().isNotEmpty);
    final hasConditions =
        conditionsPaiement != null && conditionsPaiement.isNotEmpty;
    if (!hasDelai && !hasConditions) {
      return pw.SizedBox.shrink();
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (hasDelai)
          pw.Text(
            'Délai de livraison : ${delaiLivraison is int ? "$delaiLivraison jours" : delaiLivraison}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        if (hasDelai && hasConditions) pw.SizedBox(height: 6),
        if (hasConditions)
          pw.Text(
            'Conditions de paiement : $conditionsPaiement',
            style: const pw.TextStyle(fontSize: 12),
          ),
      ],
    );
  }

  // Construire les totaux
  pw.Widget _buildTotals(Map<String, dynamic> document, {bool compact = false}) {
    // Convertir en double de manière sécurisée
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    final montantHT = parseDouble(document['montant_ht']);
    final tvaPercent = parseDouble(
      document['tva'],
    ); // TVA en pourcentage (0, 18, 20, etc.)
    final montantTTC = parseDouble(
      document['total_ttc'],
    ); // Utiliser le montant TTC du document

    // Calculer le montant TVA : différence entre TTC et HT, ou calculer à partir du pourcentage
    final montantTVA =
        montantTTC > 0
            ? montantTTC -
                montantHT // Utiliser la différence si TTC est disponible
            : montantHT *
                (tvaPercent / 100); // Sinon calculer à partir du pourcentage

    // Utiliser le TTC du document s'il est disponible, sinon calculer
    final montantTTCFinal =
        montantTTC > 0 ? montantTTC : montantHT + montantTVA;

    final padding = compact ? 10.0 : 15.0;
    final totalFontSize = compact ? 12.0 : 16.0;
    final spacing = compact ? 5.0 : 10.0;
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (tvaPercent > 0 || montantTVA > 0) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${tvaRateLabelCi(tvaPercent)}:',
                    style: pw.TextStyle(
                        fontSize: compact ? 9.0 : 12.0)),
                pw.Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(montantTVA)} FCFA',
                  style: pw.TextStyle(
                      fontSize: compact ? 9.0 : 12.0),
                ),
              ],
            ),
            pw.SizedBox(height: compact ? 3.0 : 5.0),
          ],
          pw.SizedBox(height: spacing),
          pw.Container(
            padding: pw.EdgeInsets.all(compact ? 6.0 : 10.0),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              border: pw.Border.all(color: PdfColors.blue300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL TTC:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: totalFontSize,
                  ),
                ),
                pw.Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(montantTTCFinal)} FCFA',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: totalFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construire les informations supplémentaires (délai de livraison et garantie)
  pw.Widget _buildAdditionalInfo(Map<String, dynamic> devis,
      {bool compact = false}) {
    final delaiLivraison = devis['delai_livraison']?.toString();
    final garantie = devis['garantie']?.toString();

    if ((delaiLivraison == null || delaiLivraison.isEmpty) &&
        (garantie == null || garantie.isEmpty)) {
      return pw.SizedBox.shrink();
    }

    final padding = compact ? 10.0 : 15.0;
    final fontSize = compact ? 10.0 : 12.0;
    final spacing = compact ? 6.0 : 10.0;
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (delaiLivraison != null && delaiLivraison.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Délai de livraison: ',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    delaiLivraison,
                    style: pw.TextStyle(fontSize: fontSize),
                  ),
                ),
              ],
            ),
            if (garantie != null && garantie.isNotEmpty)
              pw.SizedBox(height: spacing),
          ],
          if (garantie != null && garantie.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Garantie: ',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    garantie,
                    style: pw.TextStyle(fontSize: fontSize),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Construire les conditions de règlement
  pw.Widget _buildPaymentConditions(Map<String, dynamic> devis,
      {bool compact = false}) {
    final conditions = devis['conditions']?.toString();

    if (conditions == null || conditions.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final padding = compact ? 10.0 : 15.0;
    final fontSize = compact ? 10.0 : 12.0;
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Condition de règlement: ',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: fontSize),
          ),
          pw.Expanded(
            child: pw.Text(conditions,
                style: pw.TextStyle(fontSize: fontSize)),
          ),
        ],
      ),
    );
  }

  // Construire les informations de paiement
  pw.Widget _buildPaymentInfo(
    Map<String, dynamic> paiement,
    Map<String, dynamic> facture,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DÉTAILS DU PAIEMENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Montant payé:'),
              pw.Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(paiement['montant'] ?? 0)} FCFA',
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Mode de paiement:'),
              pw.Text(paiement['mode_paiement'] ?? ''),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Date de paiement:'),
              pw.Text(_formatPaymentDate(paiement['date_paiement'])),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Facture associée: ${facture['reference'] ?? 'N/A'}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper pour formater la date de paiement
  String _formatPaymentDate(dynamic dateValue) {
    if (dateValue == null) {
      return 'Non spécifiée';
    }

    try {
      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return 'Format invalide';
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Date invalide';
    }
  }

  // Construire la signature (séparée du footer)
  /// [signatureSizeOverride] : largeur du bloc (ex: aligner devis sur bordereau).
  /// [signatureHeightOverride] : hauteur du bloc (par défaut proportionnelle pour bloc texte lisible).
  pw.Widget _buildSignature({
    bool compact = false,
    double? signatureSizeOverride,
    double? signatureHeightOverride,
  }) {
    if (_signatureImage == null) {
      return pw.SizedBox.shrink();
    }

    final width = signatureSizeOverride ?? (compact ? 180.0 : 220.0);
    final height = signatureHeightOverride ?? (compact ? 70.0 : 95.0);
    final topPadding = compact ? 12.0 : 20.0;
    return pw.Container(
      padding: pw.EdgeInsets.only(top: topPadding),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: width,
            height: height,
            child: pw.Image(
              _signatureImage!,
              fit: pw.BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  /// Mention légale conformité Côte d'Ivoire (factures et devis).
  pw.Widget _buildLegalMention(String documentType) {
    final text = documentType.toUpperCase() == 'FACTURE'
        ? 'Facture conforme à la réglementation en vigueur en Côte d\'Ivoire.'
        : documentType.toUpperCase() == 'DEVIS'
            ? 'Devis conforme à la réglementation en vigueur en Côte d\'Ivoire.'
            : null;
    if (text == null) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Construire le pied de page (sans signature)
  /// [companyNinea] : NINEA entreprise (affiché si renseigné).
  pw.Widget _buildFooter(Map<String, dynamic>? commercial,
      {String? companyNinea}) {
    final hasCompanyNinea =
        companyNinea != null && companyNinea.trim().isNotEmpty;
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.white),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (hasCompanyNinea) ...[
            pw.Text(
              'NINEA : $companyNinea',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
          ],
          pw.Container(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Contact : 07 88 94 43 63 - Email: alebconsulting19@gmail.com',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'S.A au Capital de 1 000 000 francs CFA. COCODY ANGRE CITE GESTOCI. 16 BP 676 Abidjan 16 - RC : CI.ABJ-2014-A-13970',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sauvegarder et ouvrir le PDF (optimisé pour réduire l'utilisation mémoire)
  Future<void> _saveAndOpenPdf(pw.Document pdf, String fileName) async {
    Uint8List? pdfBytes;
    File? file;
    try {
      final output = await getTemporaryDirectory();
      file = File('${output.path}/$fileName');

      // Générer le PDF en mémoire avec compression
      try {
        pdfBytes = await pdf.save();
      } catch (e) {
        // Si erreur de mémoire, lancer une erreur explicite
        if (e.toString().toLowerCase().contains('memory') ||
            e.toString().toLowerCase().contains('out of')) {
          // Réinitialiser les images pour libérer la mémoire
          _logoImage = null;
          _signatureImage = null;
          _imagesLoaded = false;

          throw Exception(
            'Mémoire insuffisante. Veuillez fermer d\'autres applications et réessayer.',
          );
        }

        // Si erreur liée aux images, réinitialiser et continuer sans images
        if (e.toString().toLowerCase().contains('image') ||
            e.toString().toLowerCase().contains('decode')) {
          print('⚠️ Erreur lors du traitement des images: $e');
          // Ne pas relancer l'erreur, continuer sans images
        } else {
          rethrow;
        }
      }

      // Vérifier que pdfBytes n'est pas null
      if (pdfBytes == null) {
        throw Exception('Erreur lors de la génération du PDF: données nulles');
      }

      // Vérifier la taille du PDF (max 50 MB)
      if (pdfBytes.length > 50 * 1024 * 1024) {
        throw Exception(
          'Le PDF généré est trop volumineux (${(pdfBytes.length / 1024 / 1024).toStringAsFixed(1)} MB). Veuillez réduire le nombre d\'éléments.',
        );
      }

      // Écrire le fichier par chunks pour réduire l'utilisation mémoire
      final sink = file.openWrite();
      try {
        // Écrire par chunks de 1 MB
        const chunkSize = 1024 * 1024; // 1 MB
        for (int i = 0; i < pdfBytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < pdfBytes.length)
                  ? i + chunkSize
                  : pdfBytes.length;
          sink.add(pdfBytes.sublist(i, end));
          await sink.flush();
        }
      } finally {
        await sink.close();
      }

      // Libérer la mémoire du PDF immédiatement après sauvegarde
      pdfBytes = null;

      // Attendre un peu pour laisser le système libérer la mémoire
      await Future.delayed(const Duration(milliseconds: 100));

      // Ouvrir le fichier
      final result = await OpenFile.open(file.path);

      // Vérifier le résultat et gérer les erreurs
      if (result.type != ResultType.done) {
        throw Exception(
          'Impossible d\'ouvrir le fichier PDF: ${result.message}',
        );
      }
    } catch (e) {
      // Libérer la mémoire en cas d'erreur
      pdfBytes = null;

      // Nettoyer le fichier partiel si créé
      if (file != null && await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      // Message d'erreur plus explicite
      String errorMessage = 'Erreur lors de la sauvegarde du PDF';
      if (e.toString().toLowerCase().contains('memory') ||
          e.toString().toLowerCase().contains('out of')) {
        errorMessage =
            'Mémoire insuffisante. Veuillez fermer d\'autres applications et réessayer.';
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      throw Exception(errorMessage);
    } finally {
      // S'assurer que la mémoire est libérée
      pdfBytes = null;
    }
  }

  // Partager le PDF
  Future<void> sharePdf(String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');

      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      throw Exception('Erreur lors du partage du PDF: $e');
    }
  }
}
