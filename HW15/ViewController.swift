import UIKit
import AVKit
import GPUImage


class ViewController: UIViewController {
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var originalButton: UIButton!
    
    @IBOutlet weak var switcher: UISwitch!
    
    @IBAction func actSwitch(_ sender: Any) {
        if switcher.isOn {
            videoView.isHidden = false
            imageView.isHidden = true
            player.play()
        } else {
            videoView.isHidden = true
            imageView.isHidden = false
            player.pause()
        }
    }
    
    @IBAction func setOriginalImage(_ sender: UIButton) {
        self.imageView.image = self.originalImage
        self.originalButton.isHidden = true
        self.filterForVideo(indexPath: 0)
        
    }
    /// Массив с примерами обработанных изображений
    var filtersPreview: [UIImage] = []
    var originalImage = UIImage()
    
    var videoFilters: [(GPUImageMovie, GPUImageView) -> (GPUImageMovie, GPUImageView)] = []
    var imageMovie = GPUImageMovie()
    
    var playerItem = AVPlayerItem(url: URL(fileURLWithPath: Bundle.main.path( forResource: "1", ofType: "mp4")!))
    let player = AVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        videoView.isHidden = false
        imageView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let url = URL(string: "https://source.unsplash.com/random")
        let data = try? Data(contentsOf: url!)
        let picture = UIImage(data: data!)!
        
        //MARK: -- Работа с изображением
        self.originalImage = picture
        imageView.image = originalImage
        
        //MARK: Демонстрация работы фильтров для фото
        filtersPreview.append(GammasAdjustment(image: picture, gamma: 0.5))
        filtersPreview.append(filtersCombination(image: picture))
        filtersPreview.append(visualEffects(image: picture))
        filtersPreview.append(visualEffectsCombination(image: picture))
        filtersPreview.append(lutFilter(image: picture))
        
        //MARK: Демонстрация работы фильтров для видео
        videoFilters.append(GammasAdjustment)
        videoFilters.append(filtersCombination)
        videoFilters.append(visualEffects)
        videoFilters.append(visualEffectsCombination)
        videoFilters.append(lutFilter(gpuMovie:filterView:))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        player.replaceCurrentItem(with: playerItem)
        let layer = AVPlayerLayer(player: player)
        layer.frame = videoView.bounds
        
        videoView.layer.addSublayer(layer)
        player.play()
        player.actionAtItemEnd = .none
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.Repeater(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    @objc func Repeater(_ snitch: Notification) {
        let X: AVPlayerItem = snitch.object as! AVPlayerItem
        X.seek(to: .zero) { _ in }
    }

    
    // MARK: - Фильтры -
    
    // 1
    // https://github.com/BradLarson/GPUImage#color-adjustments
    func GammasAdjustment(image: UIImage, gamma: CGFloat) -> UIImage {
        let stillImageSource = GPUImagePicture(image: image)!
        let stillImageFilter = GPUImageGammaFilter()
        stillImageFilter.gamma = gamma // gamma: 0.0 - 3.0, default: 1.0
        stillImageSource.addTarget(stillImageFilter)
        stillImageFilter.useNextFrameForImageCapture()
        stillImageSource.processImage()
        return stillImageFilter.imageFromCurrentFramebuffer()
    }
    
    // video filter
    func GammasAdjustment(gpuMovie: GPUImageMovie, filterView: GPUImageView) -> (GPUImageMovie, GPUImageView) {
        let stillVideoFilter = GPUImageGammaFilter()
        stillVideoFilter.gamma = 0.5
        gpuMovie.addTarget(stillVideoFilter)
        stillVideoFilter.addTarget(filterView)
        return (gpuMovie, filterView)
    }
    
    // 2
    func filtersCombination(image: UIImage) -> UIImage {
        let stillImageSource = GPUImagePicture(image: image)!
        let stillImageFilter1 = GPUImageBrightnessFilter()
        stillImageSource.addTarget(stillImageFilter1) // первый фильтр
        let stillImageFilter2 = GPUImageExposureFilter()
        stillImageFilter1.addTarget(stillImageFilter2) // второй фильтр поверх первого
        let stillImageFilter3 = GPUImageContrastFilter()
        stillImageFilter2.addTarget(stillImageFilter3) // третий фильтр поверх второго
        
        // финальная обработка фильтров и сборка итогового изображения
        stillImageFilter3.useNextFrameForImageCapture()
        stillImageSource.processImage()
        return stillImageFilter3.imageFromCurrentFramebuffer()
    }
    // video filter
    func filtersCombination(gpuMovie: GPUImageMovie, filterView: GPUImageView) -> (GPUImageMovie, GPUImageView) {
        let stillVideoFilter1 = GPUImageBrightnessFilter()
        gpuMovie.addTarget(stillVideoFilter1)
        stillVideoFilter1.addTarget(filterView)
        let stillVideoFilter2 = GPUImageExposureFilter()
        gpuMovie.addTarget(stillVideoFilter2)
        stillVideoFilter2.addTarget(stillVideoFilter1)
        let stillVideoFilter3 = GPUImageContrastFilter()
        gpuMovie.addTarget(stillVideoFilter3)
        stillVideoFilter3.addTarget(stillVideoFilter2)
        return (gpuMovie, filterView)
    }
    
    // 3
    // https://github.com/BradLarson/GPUImage#visual-effects
    func visualEffects(image: UIImage) -> UIImage {
        let stillImageSource = GPUImagePicture(image: image)!
        let stillImageFilter = GPUImagePixellateFilter()
        stillImageFilter.fractionalWidthOfAPixel = 0.015
        stillImageSource.addTarget(stillImageFilter)
        stillImageFilter.useNextFrameForImageCapture()
        stillImageSource.processImage()
        return stillImageFilter.imageFromCurrentFramebuffer()
    }
    
    // video filter
    func visualEffects(gpuMovie: GPUImageMovie, filterView: GPUImageView) -> (GPUImageMovie, GPUImageView) {
        let stillVideoFilter = GPUImagePixellateFilter()
        stillVideoFilter.fractionalWidthOfAPixel = 0.015
        gpuMovie.addTarget(stillVideoFilter)
        stillVideoFilter.addTarget(filterView)
        return (gpuMovie, filterView)
    }
    
    // 4
    func visualEffectsCombination(image: UIImage) -> UIImage {
        let stillImageSource = GPUImagePicture(image: image)!
        
        let stillImageFilter1 = GPUImageBulgeDistortionFilter()
        stillImageSource.addTarget(stillImageFilter1) // первый фильтр
        let stillImageFilter2 = GPUImageCGAColorspaceFilter()
        stillImageFilter1.addTarget(stillImageFilter2) // второй фильтр поверх первого
        
        // финальная обработка фильтров и сборка итогового изображения
        stillImageFilter2.useNextFrameForImageCapture()
        stillImageSource.processImage()
        return stillImageFilter2.imageFromCurrentFramebuffer()
    }
    // video filter
    func visualEffectsCombination(gpuMovie: GPUImageMovie, filterView: GPUImageView) -> (GPUImageMovie, GPUImageView) {
        let stillVideoFilter1 = GPUImageBulgeDistortionFilter()
        gpuMovie.addTarget(stillVideoFilter1, atTextureLocation: 0)
        stillVideoFilter1.addTarget(filterView)
        
        let stillVideoFilter2 = GPUImageCGAColorspaceFilter()
        gpuMovie.addTarget(stillVideoFilter2, atTextureLocation: 1)
        stillVideoFilter2.addTarget(stillVideoFilter1)
        return (gpuMovie, filterView)
    }
    
    // 5 - цветокор
    // https://obsproject.com/forum/resources/free-lut-filter-pack.594/
    func lutFilter(image: UIImage) -> UIImage {
        let picture = GPUImagePicture(image: image)!
        let filter = GPUImageLookupFilter()
        let lut = GPUImagePicture(image: UIImage(named: "webcam_preset_1"))!
        picture.addTarget(filter, atTextureLocation: 0)
        lut.addTarget(filter, atTextureLocation: 1)
        filter.useNextFrameForImageCapture()
        picture.processImage()
        lut.processImage()
        return filter.imageFromCurrentFramebuffer()
    }
    
    // video filter
    func lutFilter(gpuMovie: GPUImageMovie, filterView: GPUImageView) -> (GPUImageMovie, GPUImageView) {
        
        let filter = GPUImageLookupFilter()
        let lut = GPUImagePicture(image: UIImage(named: "webcam_preset_1"))!
        lut.addTarget(filter, atTextureLocation: 0)
        let filter2 = GPUImageFilter()
        filter.useNextFrameForImageCapture()
        lut.processImage()
        filter.addTarget(filter2, atTextureLocation: 1)
        gpuMovie.addTarget(filter2, atTextureLocation: 2)
        filter2.addTarget(filterView)
        return (gpuMovie, filterView)
    }
    
    //MARK: - Применение фильтра к видео -
    func filterForVideo(indexPath: Int) {
        DispatchQueue.main.async {
            self.imageMovie.removeAllTargets()
            self.videoView.layer.sublayers = nil
        }
        
        guard videoView.layer.sublayers?.isEmpty == false else { return }
        
        DispatchQueue.main.async {
            self.imageMovie.playerItem = self.playerItem
            self.imageMovie.runBenchmark = true
            self.imageMovie.playAtActualSpeed = false
            
            var gpuView = GPUImageView()
            (self.imageMovie, gpuView) = self.videoFilters[indexPath](self.imageMovie, gpuView)
            
            gpuView.frame = self.videoView.bounds
            self.videoView.layer.addSublayer(gpuView.layer)
            self.imageMovie.startProcessing()
        }
    }
}

//MARK: - Extensions -

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filtersPreview.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        cell.imageView.image = self.filtersPreview[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        originalButton.isHidden = false
        self.imageView.image = self.filtersPreview[indexPath.item]
        self.filterForVideo(indexPath: indexPath.item)
    }
}
