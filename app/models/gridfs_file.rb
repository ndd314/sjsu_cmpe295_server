class GridfsFile
  class GridFsFileException < StandardError; end

  include Mongoid::Document

  belongs_to :folder

  validates_presence_of :folder, :name
  validates_format_of :name, with: /\A[a-z0-9 \-_\.]*\Z/i
  validates_uniqueness_of :name, scope: :folder
  validates_presence_of :file_id, message: 'File has not been uploaded'
  validate :file_exists_on_gridfs

  delegate :owner, to: :folder
  delegate :length, :chunkSize, :uploadDate, :md5, :contentType, :metadata, :data_uri, :data, to: :grid_fs_file

  after_destroy :delete_grid_fs_file

  field :name, type: String
  field :file_id, type: String

  def upload!(stream)
    raise GridFsFileException.new('Upload is not possible.') if self.file_id
    begin
      @grid_fs_file = grid_fs.put(stream)
      self.file_id = grid_fs_file.id
      save!
    rescue StandardError => e
      raise GridFsFileException.new('Error in upload #{e.message}')
    end
  end

  private

  def delete_grid_fs_file
    grid_fs.delete(file_id)
  end

  def file_exists_on_gridfs
    grid_fs_file rescue errors.add(:base, 'File does not exist in GridFS')
  end

  def grid_fs_file
    @grid_fs_file ||= grid_fs.get(file_id)
  end

  def grid_fs
    @grid_fs ||= Mongoid::GridFs
  end
end
