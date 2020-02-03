
import 'package:expressions/expressions.dart';
import 'package:expressions/src/parser.dart';
import 'package:test/test.dart';
import 'dart:math';

main() {

  group('parse', () {

    var parser = new ExpressionParser();

    test('identifier', () {

      for (var v in [
        "foo", "_value", r"$x1"
      ]) {
        expect(parser.identifier.parse(v).value.name, v);
      }

      for (var v in [
        "1", "-qdf",".sfd"
      ]) {
        expect(parser.identifier.parse(v).isSuccess, isFalse);
      }
    });

    test('numeric literal', () {
      for (var v in [
        "134", ".5", "43.2", "1e3", "1E-3", "1e+0", "0x01"
      ]) {
        var w = parser.numericLiteral.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.value, num.parse(v));
        expect(w.value.raw, v);
      }

      for (var v in [
        "-134", 
        // "1e5E3", ".5.4", TODO: Failed, why?
      ]) {

        expect(parser.numericLiteral.parse(v).isSuccess, isFalse);
      }
    });

    test('string literal', () {
      for (var v in <String>[
        "'qf sf q'", "'qfqsd\"qsfd'", "'qsd\\nfqs\\'qsdf'",
        '"qf sf q"', '"qfqsd\'qsfd"', '"qsdf\\tqs\\"qsdf"',
      ]) {
        var w = parser.stringLiteral.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.value, parser.unescape(v.substring(1,v.length-1)));
        expect(w.value.raw, v);
      }

      for (var v in [
        "sd'<sdf'",
        // "'df'sdf'"// TODO: Failed, why?
      ]) {
        expect(parser.stringLiteral.parse(v).isSuccess, isFalse);
      }

    });
    test('bool literal', () {
      for (var v in <String>["true","false"]) {
        var w = parser.boolLiteral.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.value, v=="true");
        expect(w.value.raw, v);
      }

      for (var v in ["True","False"]) {
        expect(parser.boolLiteral.parse(v).isSuccess, isFalse);
      }

    });

    test('null literal', () {
      for (var v in <String>["null"]) {
        var w = parser.nullLiteral.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.value, isNull);
        expect(w.value.raw, v);
      }

      for (var v in ["NULL"]) {
        expect(parser.nullLiteral.parse(v).isSuccess, isFalse);
      }

    });

    test('this literal', () {
      for (var v in <String>["this"]) {
        var w = parser.thisExpression.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value, new isInstanceOf<ThisExpression>());
      }
    });

    test('array literal', () {
      for (var v in <String>[
        "[1, 2, 3]"
      ]) {
        var w = parser.arrayLiteral.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.value, [new Literal(1), new Literal(2), new Literal(3)]);
        expect(w.value.raw, v);
      }

      for (var v in ["[1,2["]) {
        expect(parser.arrayLiteral.parse(v).isSuccess, isFalse);
      }

    });

    test('token', () {
      for (var v in <String>[
        "x", "_qsdf", "x.y", "a[1]", "a.b[c]", "f(1, 2)", "(a+B).x",
        "foo.bar(baz)", "1", '"abc"', "(a%2)"
      ]) {
        var w = parser.token.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.toTokenString(), v);
      }
    });

    test('binary expression', () {
      for (var v in <String>[
        "1", "1+2", "a+b*2-Math.sqrt(2)", "-1+2",
        "1+4-5%2*5<4==(2+1)*1<=2&&2||2"
      ]) {
        var w = parser.binaryExpression.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.toString(), v);
      }
    });

    test('unary expression', () {
      for (var v in <String>[
        "+1", "-a", "!true", "~0x01"
      ]) {
        var w = parser.unaryExpression.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.toString(), v);
      }
    });

    test('conditional expression', () {
      for (var v in <String>[
        "1<2 ? 'always' : 'never'"
      ]) {
        var w = parser.expression.parse(v);
        expect(w.isSuccess, isTrue, reason: "Failed parsing `$v`");
        expect(w.value.toString(), v);
      }
    });


  });

  group('evaluation', () {

    var evaluator = const ExpressionEvaluator();

    test('math and logical expressions', () {

      var context = {
        "x": 3,
        "y": 4,
        "z": 5
      };
      var expressions = {
        "1+2": 3,
        "-1+2": 1,
        "1+4-5%2*3": 2,
        "x*x+y*y==z*z": true
      };

      expressions.forEach((e,r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });

    });
    test('index expressions', () {

      var context = {
        "l": [1,2,3],
        "m": {
          "x": 3,
          "y": 4,
          "z": 5,
          "s": [null]
        }
      };
      var expressions = {
        "l[1]": 2,
        "m['z']": 5,
        "m['s'][0]": null
      };

      expressions.forEach((e,r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });

    });
    test('call expressions', () {

      var context = {
        "x": 3,
        "y": 4,
        "z": 5,
        "sqrt": sqrt,
      };
      var expressions = {
        "sqrt(x*x+y*y)": 5
      };

      expressions.forEach((e,r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });

    });
    test('conditional expressions', () {

      var context = {
        "this": [],
        "other": {}
      };
      var expressions = {
        "this==other ? 'same' : 'different'": 'different'
      };

      expressions.forEach((e,r) {
        expect(evaluator.eval(Expression.parse(e), context), r);
      });

    });

  });
}