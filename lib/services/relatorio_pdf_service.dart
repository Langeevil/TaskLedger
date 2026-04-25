import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/relatorio_model.dart';
import '../utils/app_currency_utils.dart';
import '../utils/app_date_utils.dart';

class RelatorioPdfService {
  Future<String> gerarESalvarPdf({required RelatorioResumoModel resumo}) async {
    final bytes = await _gerarPdf(resumo: resumo);
    final nomeArquivo =
        'relatorio_taskledger_${DateTime.now().millisecondsSinceEpoch}';

    return FileSaver.instance.saveFile(
      name: nomeArquivo,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  Future<Uint8List> _gerarPdf({required RelatorioResumoModel resumo}) async {
    final pdf = pw.Document();
    final geradoEm = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) {
          return [
            _cabecalho(
              titulo: 'Relatório TaskLedger',
              subtitulo:
                  'Gerado em ${AppDateUtils.format(geradoEm)} com base nos dados consolidados do app.',
            ),
            pw.SizedBox(height: 20),
            _secao(
              titulo: 'Resumo executivo',
              child: pw.Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _cartaoResumo('Tarefas ativas', '${resumo.tarefasAtivas}'),
                  _cartaoResumo(
                    'Tarefas vencidas',
                    '${resumo.tarefasVencidas}',
                  ),
                  _cartaoResumo('Projetos', '${resumo.totalProjetos}'),
                  _cartaoResumo('Saldo atual', _formatarMoeda(resumo.saldo)),
                ],
              ),
            ),
            _secao(
              titulo: 'Financeiro',
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Receitas: ${_formatarMoeda(resumo.totalReceitas)}',
                    style: _textoPadrao(negrito: true),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Despesas: ${_formatarMoeda(resumo.totalDespesas)}',
                    style: _textoPadrao(negrito: true),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Saldo: ${_formatarMoeda(resumo.saldo)}',
                    style: _textoPadrao(negrito: true),
                  ),
                  pw.SizedBox(height: 12),
                  _tabelaSerie(
                    titulo: 'Top categorias',
                    itens: resumo.totaisPorCategoria,
                    monetario: true,
                  ),
                ],
              ),
            ),
            _secao(
              titulo: 'Tarefas',
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _tabelaSerie(
                    titulo: 'Distribuição por status',
                    itens: resumo.tarefasPorStatus,
                  ),
                  pw.SizedBox(height: 12),
                  _tabelaSerie(
                    titulo: 'Distribuição por prioridade',
                    itens: resumo.tarefasPorPrioridade,
                  ),
                ],
              ),
            ),
            _secao(
              titulo: 'Projetos e planejamento',
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _tabelaSerie(
                    titulo: 'Distribuição por status',
                    itens: resumo.planejamentosPorStatus,
                  ),
                  pw.SizedBox(height: 12),
                  _tabelaSerie(
                    titulo: 'Distribuição por prioridade',
                    itens: resumo.planejamentosPorPrioridade,
                  ),
                ],
              ),
            ),
            if (resumo.ultimaAtualizacao != null)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Última atualização dos projetos: ${AppDateUtils.format(resumo.ultimaAtualizacao!)}',
                  style: _textoPadrao(tamanho: 10, cor: PdfColors.blueGrey700),
                ),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _cabecalho({required String titulo, required String subtitulo}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEEF2FF),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromInt(0xFF6366F1), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF1E1B4B),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(subtitulo, style: _textoPadrao(cor: PdfColors.blueGrey800)),
        ],
      ),
    );
  }

  pw.Widget _secao({required String titulo, required pw.Widget child}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blueGrey100),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF111827),
            ),
          ),
          pw.SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  pw.Widget _cartaoResumo(String titulo, String valor) {
    return pw.Container(
      width: 240,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: _textoPadrao(tamanho: 10, cor: PdfColors.blueGrey800),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _tabelaSerie({
    required String titulo,
    required List<RelatorioSerieItem> itens,
    bool monetario = false,
  }) {
    if (itens.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo, style: _textoPadrao(negrito: true)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Sem dados suficientes.',
            style: _textoPadrao(cor: PdfColors.blueGrey700),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo, style: _textoPadrao(negrito: true)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Item', 'Valor'],
          data: itens
              .map(
                (item) => [
                  item.label,
                  monetario
                      ? _formatarMoeda(item.valor)
                      : item.valor.toInt().toString(),
                ],
              )
              .toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF6366F1),
          ),
          cellStyle: _textoPadrao(),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
          cellPadding: const pw.EdgeInsets.all(8),
        ),
      ],
    );
  }

  pw.TextStyle _textoPadrao({
    double tamanho = 11,
    bool negrito = false,
    PdfColor cor = PdfColors.black,
  }) {
    return pw.TextStyle(
      fontSize: tamanho,
      fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: cor,
    );
  }

  String _formatarMoeda(double valor) {
    return AppCurrencyUtils.format(valor);
  }
}
