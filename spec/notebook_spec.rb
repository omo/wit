
require 'wit'
require 'nokogiri'

describe Wit::Notebook do
  context do
    before(:each) do 
      @book = Wit::Notebook.new("./")
    end

    it "makes a name from date like URL components" do
      name = @book.name_from_components("2013", "06", "09", "1234", "hello", :md)
      expect(name.filename).to eq("./2013_06/2013_06_09_1234_hello.md")
    end

    it "makes a name even without specifying title" do
      name = @book.name_from_components("2013", "06", "09", "1234", nil, :md)
      expect(name.filename).to eq("./2013_06/2013_06_09_1234_index.md")
    end

    it "makes a name of a fresh note" do
      name = @book.fresh_note_name(nil)
      expect(name.exist?).to be_false
    end

    it "makes a name of a fresh note with title" do
      name = @book.fresh_note_name("This is title.")
      expect(File.basename(name.filename)).to end_with("this-is-title.md")
    end

  end

  context do
    before(:each) do 
      @book = Wit::Notebook.new("./t")
    end

    it "lists latest notebook names" do
      note_names = @book.latest_note_names.to_a
      expect(note_names.size).to be > 3
      note_names.each do |n|
        expect(File.exist?(n.filename)).to be_true
      end
    end
  end

end

describe Wit::Name do
  context do
    before(:each) do 
      @book = Wit::Notebook.new("./t")
    end

    it "responts exist?" do
      nosuch = @book.name_from_components("2013", "06", "09", "1234", "hello", :md)
      expect(nosuch.exist?).to be_false
      forreal = @book.name_from_components("2012", "01", "02", "1234", "hello", :md)
      expect(forreal.exist?).to be_true
    end

    it "has url" do
      name = @book.name_from_components("2013", "06", "09", "1234", "hello", :md)
      expect(name.url).to eq("/2013/06/09/1234-hello")
    end

    it "has short url for index" do
      name = @book.name_from_components("2013", "06", "09", "1234", nil, :md)
      expect(name.url).to eq("/2013/06/09/1234")
    end

    it "walks around tree" do
      middle = @book.name_from_components("2012", "01", "02", "1234", "hello", :md)
      next1 = middle.walk(1)
      expect(next1).to eq(@book.name_from_components("2012", "01", "02", "2345", nil, :md))
      next2 = next1.walk(1)
      expect(next2.filename).to include("2013")

      prev1 = middle.walk(-1)
      expect(prev1).to eq(@book.name_from_components("2012", "01", "02", "0123", "fuh", :md))
      prev2 = prev1.walk(-1)
      expect(prev2).to eq(@book.name_from_components("2011", "12", "31", "0123", "yearend", :md))
      prev3 = prev2.walk(-1)
      expect(prev3).to eq(@book.name_from_components("2011", "12", "25", "1201", "xmas", :md))
      prev4 = prev3.walk(-1)
      expect(prev4).to be_nil
    end
  end
end

def testdata_named(name)
  File.join(File.dirname(__FILE__), "testdata", name)
end

describe Wit::Note do
  context do
    before(:each) do 
      @book = Wit::Notebook.new("./")
      @hello_note = Wit::Name.new(testdata_named("hello.md")).to_note
    end

    it "should respond exist?" do
      expect(@hello_note.exist?).to be_true
    end

    it "should have header hash" do
      expect(@hello_note.head["message"]).to eq("Hello")
    end

    it "should have body HTML" do
      html = Nokogiri::HTML(@hello_note.body)
      expect(html.css('h1')[0].content).to eq("The Title")
    end
  end
end

