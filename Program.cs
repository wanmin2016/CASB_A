using System;

namespace MyApp
{
    class Program
    {
        static void Main(string[] args)
        {
            // 定义三个委托变量
            MyDelegate d1, d2, d3;
            // d1关联TestMethod1方法
            d1 = TestMethod1;
            // d2关联TestMethod2方法
            d2 = TestMethod2;
            // d3关联TestMethod3方法
            d3 = TestMethod3;
            // 分别调用三个委托实例
            Console.WriteLine("分别调用三个委托实例，输出结果如下：");
            d1("d1");
            d2("d2");
            d3("d3");
/*----------------------------------------------------------------------*/
            // 先与TestMethod1方法关联
            MyDelegate d4 = TestMethod1;
            // 随后再与TestMethod2和TestMethod3方法关联
            d4 += TestMethod2;
            d4 += TestMethod3;
            // 调用d4
            Console.WriteLine("\n调用d4可同时调用三个方法，结果如下：");
            d4("d4");
/*-----------------------------------------------------------------------*/
            // 从d4中关联的方法列表中减去TestMethod2方法
            d4 -= TestMethod2;
            // 再次调用d4
            Console.WriteLine("\n移除与TestMethod2方法关联后：");
            d4("d4");
            Console.Read();
        }

        #region 定义委托
        public delegate void MyDelegate(string s);
        #endregion

        #region 方法定义
        static void TestMethod1(string str)
        {
            Console.WriteLine("这是方法一。参数：{0}", str);
        }
        static void TestMethod2(string str)
        {
            Console.WriteLine("这是方法二。参数：{0}", str);
        }
        static void TestMethod3(string str)
        {
            Console.WriteLine("这是方法三。参数：{0}", str);
        }
        #endregion
    }
}
