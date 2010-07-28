// wesabe.require('util.Timer');

Screw.Unit(function() {
  describe("Timer", function() {
    before(function() {
      timer = new wesabe.util.Timer();
    })
    
    describe("#start", function() {
      it("creates a new timing record", function() {
        timer.start('foo');
        expect(timer.data.foo).to(have_length, 1);
      });

      describe("without passing a callback function", function() {
        it("returns the index of the timer", function() {
          expect(timer.start('foo')).to(equal, 0);
          expect(timer.start('foo')).to(equal, 1);
        });
      });
      
      describe("when passing a function", function() {
        it("calls #end for you", function() {
          timer.start('foo', function(){});
          expect(timer.data.foo[0].end).to_not(be_null);
        });
      });
    });
    
    describe("#end", function() {
      it("terminates a timing record", function() {
        timer.start('foo'); timer.end('foo'); timer.start('foo');
        expect(timer.data.foo).to(have_length, 2);
      });
    });
    
    describe("#summarize", function() {
      describe("when given a single timing record", function() {
        it("returns the time taken for that record", function() {
          timer.start('foo', function() { sleep(0.01) });
          expect(timer.summarize().foo)
            .to(equal, timer.data.foo[0].end-timer.data.foo[0].start);
        });
      });
      
      describe("when given multiple timing records", function() {
        it("returns the sum of the times for the records", function() {
          timer.start('foo', function() { sleep(0.01) });
          timer.start('foo', function() { sleep(0.01) });
          expect(timer.summarize().foo)
            .to(equal, timer.data.foo[0].end-timer.data.foo[0].start+
                       timer.data.foo[1].end-timer.data.foo[1].start);
        });
      });
    });
  });
});
