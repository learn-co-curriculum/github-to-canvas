class CourseCreationInterface

  def initialize(file)
    data = YAML.load(File.read("#{Dir.pwd}/#{file}"))
    CanvasInterface.create_new_course(data["name"])
  end

  
end