import javax.xml.xpath.*;
import java.io.*;

public class XPathValidator {
  private String xpath;

  public XPathValidator(String xpath) {
    this.xpath = xpath;
  }

  public void validate() throws XPathExpressionException {
    XPathFactory factory = XPathFactory.newInstance();
    XPath xpath = factory.newXPath();
    XPathExpression expression = xpath.compile(this.xpath);
    // do nothing with expression, just don't 'splode
  }

  public static void main(String args[]) {
    BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
    try {
      String xpath;
      while (in.ready()) {
        xpath = in.readLine();
        // write a single line of output with an error message,
        // if there is one, for every line of input
        try {
          new XPathValidator(xpath).validate();
          System.out.println();
        } catch (XPathExpressionException e) {
          System.out.println(e.getCause().getMessage());
        }
      }
    } catch (IOException e) {
      System.err.println("Could not read xpaths from stdin.");
      System.exit(1);
    }
  }
}
