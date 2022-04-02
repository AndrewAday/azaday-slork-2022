public class Fuzz extends Chugen
{
  -5.0 => float a;  // keep between [-inf, -4.5]
  .1 => float m;

  fun float tick(float in) {
    in/Std.fabs(in) => float q;
    q * (1.0 - Math.exp(a*q*in)) => float y;
    return m*y + (1-m)*in;
  }

  fun float level(float l) {
    l => this.a;
    return l;
  }

  fun float level() {
    return this.a;
  }

  fun float mix(float m) {
    Math.max(0., Math.min(.999, m)) => this.m; // clamp!
  }

  fun float mix() {
    return this.m;
  }
}
