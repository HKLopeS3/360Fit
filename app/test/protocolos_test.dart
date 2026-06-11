import 'package:fit360_app/core/calculos/protocolos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Siri', () {
    test('densidade 1.07 → ~12.6% de gordura', () {
      expect(percentualGorduraSiri(1.07), closeTo(12.61, 0.1));
    });
    test('densidade 1.05 → ~21.4%', () {
      expect(percentualGorduraSiri(1.05), closeTo(21.43, 0.1));
    });
  });

  group('Pollock 3 dobras', () {
    test('homem 30 anos, soma 45mm (15+15+15)', () {
      final d = densidadePollock3(
        sexo: Sexo.masculino,
        idade: 30,
        dobras: const Dobras(peitoral: 15, abdominal: 15, coxa: 15),
      );
      // 1.10938 - 0.0008267*45 + 0.0000016*2025 - 0.0002574*30
      expect(d, closeTo(1.0679, 0.001));
      expect(percentualGorduraSiri(d), closeTo(13.5, 0.5));
    });
    test('mulher 25 anos, soma 60mm', () {
      final d = densidadePollock3(
        sexo: Sexo.feminino,
        idade: 25,
        dobras: const Dobras(tricipital: 20, suprailiaca: 20, coxa: 20),
      );
      expect(d, closeTo(1.0451, 0.001));
    });
  });

  group('Pollock 7 dobras', () {
    test('homem 30 anos, soma 105mm (15mm × 7)', () {
      final d = densidadePollock7(
        sexo: Sexo.masculino,
        idade: 30,
        dobras: const Dobras(
          tricipital: 15,
          subescapular: 15,
          peitoral: 15,
          axilarMedia: 15,
          suprailiaca: 15,
          abdominal: 15,
          coxa: 15,
        ),
      );
      // 1.112 - 0.00043499*105 + 0.00000055*11025 - 0.00028826*30
      expect(d, closeTo(1.0639, 0.001));
    });
  });

  group('1RM', () {
    test('Epley: 100kg × 10 reps → 133.3kg', () {
      expect(umRmEpley(100, 10), closeTo(133.33, 0.1));
    });
    test('Brzycki: 100kg × 10 reps → 133.3kg', () {
      expect(umRmBrzycki(100, 10), closeTo(133.33, 0.1));
    });
    test('1 repetição é o próprio 1RM', () {
      expect(umRmEpley(80, 1), closeTo(82.7, 0.1));
      expect(umRmBrzycki(80, 1), closeTo(80.0, 0.1));
    });
  });

  group('Cooper', () {
    test('2400m em 12min → VO₂ ~42.4', () {
      expect(vo2Cooper(2400), closeTo(42.37, 0.1));
    });
    test('classificação masculina', () {
      expect(classificacaoVo2(30, sexo: Sexo.masculino), 'Fraco');
      expect(classificacaoVo2(38, sexo: Sexo.masculino), 'Regular');
      expect(classificacaoVo2(45, sexo: Sexo.masculino), 'Bom');
      expect(classificacaoVo2(55, sexo: Sexo.masculino), 'Excelente');
    });
  });

  group('Wells', () {
    test('classificação feminina', () {
      expect(classificacaoWells(25, sexo: Sexo.feminino), 'Fraco');
      expect(classificacaoWells(33, sexo: Sexo.feminino), 'Regular');
      expect(classificacaoWells(40, sexo: Sexo.feminino), 'Bom');
      expect(classificacaoWells(45, sexo: Sexo.feminino), 'Excelente');
    });
  });
}
