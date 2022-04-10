public class OverDrive extends Chugen
{
    .1 => float m;

    fun float tick(float in)
    {
        float ret;
        if (Std.fabs(in) < 1.0/3) {
          2 * in => ret;
        } else if (Std.fabs(in) < 2.0/3) {
          (1/3.0) * (3 - Math.pow((2 - 3 * in), 2)) => ret;
        } else if (in < 0) {
          -1.0 => ret;
        } else {
          1.0 => ret;
        }

        return m*ret + (1-m)*in;
    }


    fun float mix(float m) {
      Math.max(0.0, Math.min(.999, m)) => this.m;  // clamp!
    }

    fun float mix() {
      return this.m;
    }
}
