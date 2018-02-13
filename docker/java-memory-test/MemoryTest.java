// from https://stackoverflow.com/questions/23701207/why-do-xmx-and-runtime-maxmemory-not-agree

import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryPoolMXBean;

public class MemoryTest {
  static String mb (long s) {
    return String.format("%d (%.2f M)", s, (double)s / (1024 * 1024));
  }

  public static void main(String[] args) {
    System.out.println("Runtime max: " + mb(Runtime.getRuntime().maxMemory()));
    MemoryMXBean m = ManagementFactory.getMemoryMXBean();

    System.out.println("Non-heap: " + mb(m.getNonHeapMemoryUsage().getMax()));
    System.out.println("Heap: " + mb(m.getHeapMemoryUsage().getMax()));

    for (MemoryPoolMXBean mp : ManagementFactory.getMemoryPoolMXBeans()) {
      System.out.println("Pool: " + mp.getName() + 
                         " (type " + mp.getType() + ")" +
                         " = " + mb(mp.getUsage().getMax()));
    }
  }
}