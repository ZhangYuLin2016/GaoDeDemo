//
//  ViewController.m
//  GaoDeDemo
//
//  Created by hgy on 16/6/8.
//  Copyright © 2016年 hgy. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import <AMapSearchKit/AMapSearchKit.h>
#define APIKey @"2a842e571dadd9effa3349e4e23a6544"
#import "annotationView.h"

@interface ViewController ()<MAMapViewDelegate , AMapSearchDelegate , UITableViewDelegate , UITableViewDataSource , UIGestureRecognizerDelegate>
{
    MAMapView *_mapView;
    UIButton *_locationButton;
    AMapSearchAPI *_search;
    CLLocation *_currentLocation;
    
    UITableView *_tableViews;
    NSArray *_poins;
    NSMutableArray *_anonatation;
    //长按手势用于路线规划
    UILongPressGestureRecognizer *_longPressGesture;
    //目的地的坐标
    MAPointAnnotation *_destinationPoint;
    
    //存放路线规划的数组
    NSArray *_pathPolylines;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGaoDeMap];
    [self initLocationButton];
    [self initSearch];
    [self initarray];
    [self inittableview];
}
-(void)initarray
{
    _anonatation = [NSMutableArray array];
    _poins = nil;
    
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _longPressGesture.delegate = self;
    [_mapView addGestureRecognizer:_longPressGesture];
}
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        //当前手势对应的经纬度坐标
        CLLocationCoordinate2D coordinate = [_mapView convertPoint:[gesture locationInView:_mapView]
                                              toCoordinateFromView:_mapView];
        
        // 添加标注
        if (_destinationPoint != nil)
        {
            // 清理
            [_mapView removeAnnotation:_destinationPoint];
            _destinationPoint = nil;
            
//            [_mapView removeOverlays:_pathPolylines];
//            _pathPolylines = nil;
        }
        
        _destinationPoint = [[MAPointAnnotation alloc] init];
        _destinationPoint.coordinate = coordinate;
        _destinationPoint.title = @"Destination";
        
        [_mapView addAnnotation:_destinationPoint];
    }
    
}

-(void)inittableview
{
    CGFloat halfHeight = CGRectGetHeight(self.view.bounds) * 0.5;
    
    _tableViews = [[UITableView alloc] initWithFrame:CGRectMake(0, halfHeight, CGRectGetWidth(self.view.bounds), halfHeight) style:UITableViewStylePlain];
    _tableViews.delegate = self;
    _tableViews.dataSource = self;
    
    [self.view addSubview:_tableViews];
}
//地图
-(void)initGaoDeMap
{
    //地图api
    [MAMapServices sharedServices].apiKey = APIKey;
    //搜索api
//    [AMapSearchServices sharedServices].apiKey = APIKey;
    _mapView = [[MAMapView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) * 0.5)];
    _mapView.delegate = self;
    //附件的两个位置
    //罗盘位置
    _mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 22);
    //比例尺位置
    _mapView.scaleOrigin = CGPointMake(_mapView.scaleOrigin.x, 22);
    [self.view addSubview:_mapView];
    _mapView.showsUserLocation = YES;
    
}
//添加按钮
-(void)initLocationButton
{
    //导航
    _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locationButton.frame = CGRectMake(20, CGRectGetHeight(_mapView.bounds)-80, 40, 40);
    _locationButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _locationButton.backgroundColor = [UIColor whiteColor];
    _locationButton.layer.cornerRadius = 5;
    
    [_locationButton addTarget:self action:@selector(daohangAction) forControlEvents:UIControlEventTouchUpInside];
    [_locationButton setImage:[UIImage imageNamed:@"iconfont-daohang "] forState:UIControlStateNormal];
    [_mapView addSubview:_locationButton];
    
    //搜索
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    searchButton.frame = CGRectMake(80, CGRectGetHeight(_mapView.bounds) - 80, 40, 40);
    searchButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin;
    searchButton.backgroundColor = [UIColor whiteColor];
    [searchButton setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(searchAction)
           forControlEvents:UIControlEventTouchUpInside];
    [_mapView addSubview:searchButton];
    
    
    //查询路线
    UIButton *pathButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    pathButton.frame = CGRectMake(140, CGRectGetHeight(_mapView.bounds) - 60, 40, 40);
    pathButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    pathButton.backgroundColor = [UIColor whiteColor];
    [pathButton setImage:[UIImage imageNamed:@"ditu"] forState:UIControlStateNormal];
    
    [pathButton addTarget:self action:@selector(pathAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_mapView addSubview:pathButton];
    
    
}

- (void)pathAction
{
    
    if (_destinationPoint == nil || _currentLocation == nil || _search == nil)
    {
        NSLog(@"path search failed");
        return;
    }
//    AMapDrivingRouteSearchRequest 驾车
    // 设置为步行路径规划
    AMapWalkingRouteSearchRequest *request = [[AMapWalkingRouteSearchRequest alloc] init];
    
    request.origin = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.destination = [AMapGeoPoint locationWithLatitude:_destinationPoint.coordinate.latitude longitude:_destinationPoint.coordinate.longitude];
    
    [_search AMapWalkingRouteSearch:request];
}
//获取路线
//实现路径搜索的回调函数
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response
{
    if(response.route == nil)
    {
        return;
    }
    
    //通过AMapNavigationSearchResponse对象处理搜索结果
    [_mapView removeOverlays:_pathPolylines];
    _pathPolylines = nil;
    
    // 只显示第一条
    _pathPolylines = [self polylinesForPath:response.route.paths[0]];
    [_mapView addOverlays:_pathPolylines];
    
    [_mapView showAnnotations:@[_destinationPoint, _mapView.userLocation] animated:YES];
}
- (NSArray *)polylinesForPath:(AMapPath *)path
{
    if (path == nil || path.steps.count == 0)
    {
        return nil;
    }
    
    NSMutableArray *polylines = [NSMutableArray array];
    
    [path.steps enumerateObjectsUsingBlock:^(AMapStep *step, NSUInteger idx, BOOL *stop) {
        
        NSUInteger count = 0;
        //字符串的解析
        CLLocationCoordinate2D *coordinates = [self coordinatesForString:step.polyline
                                                         coordinateCount:&count
                                                              parseToken:@";"];
        
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
        [polylines addObject:polyline];
        
        free(coordinates), coordinates = NULL;
    }];
    
    return polylines;
}
//线路的回调方法
- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:overlay];
        
        polylineView.lineWidth   = 4;
        polylineView.strokeColor = [UIColor magentaColor];
        
        return polylineView;
    }
    
    return nil;
}

- (CLLocationCoordinate2D *)coordinatesForString:(NSString *)string
                                 coordinateCount:(NSUInteger *)coordinateCount
                                      parseToken:(NSString *)token
{
    if (string == nil)
    {
        return NULL;
    }
    
    if (token == nil)
    {
        token = @",";
    }
    
    NSString *str = @"";
    if (![token isEqualToString:@","])
    {
        str = [string stringByReplacingOccurrencesOfString:token withString:@","];
    }
    
    else
    {
        str = [NSString stringWithString:string];
    }
    
    NSArray *components = [str componentsSeparatedByString:@","];
    NSUInteger count = [components count] / 2;
    if (coordinateCount != NULL)
    {
        *coordinateCount = count;
    }
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D*)malloc(count * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0; i < count; i++)
    {
        coordinates[i].longitude = [[components objectAtIndex:2 * i]     doubleValue];
        coordinates[i].latitude  = [[components objectAtIndex:2 * i + 1] doubleValue];
    }
    
    return coordinates;
}

-(void)daohangAction
{
    if (_mapView.userTrackingMode != MAUserTrackingModeFollow) {
        [_mapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
    }
}

- (void)searchAction
{
    if (_currentLocation == nil || _search == nil)
    {
        NSLog(@"search failed");
        return; }
    //构造AMapPOIAroundSearchRequest对象，设置周边请求参数
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.keywords = @"餐饮";
    request.types = @"餐饮服务 | 生活服务";
    request.sortrule = 0;
    request.requireExtension = YES;
    request.radius = 5000;//查询半径
    //发去周边搜索
    [_search AMapPOIAroundSearch:request];
    
    // types属性表示限定搜索POI的类别，默认为：餐饮服务|商务住宅|生活服务
    // POI的类型共分为20种大类别，分别为：
    // 汽车服务|汽车销售|汽车维修|摩托车服务|餐饮服务|购物服务|生活服务|体育休闲服务|
    // 医疗保健服务|住宿服务|风景名胜|商务住宅|政府机构及社会团体|科教文化服务|
    // 交通设施服务|金融保险服务|公司企业|道路附属设施|地名地址信息|公共设施
}
/*!
 @brief 当userTrackingMode改变时，调用此接口
 @param mapView 地图View
 @param mode 改变后的mode
 @param animated 动画
 */
- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MAUserTrackingModeNone) {
        [_locationButton setImage:[UIImage imageNamed:@"iconfont-daohang "] forState:UIControlStateNormal];
    }else{
        [_locationButton setImage:[UIImage imageNamed:@"dingwei"] forState:UIControlStateNormal];
    }
}
//编码
-(void)initSearch
{
    //配置用户KEY
    [AMapSearchServices sharedServices].apiKey = APIKey;
    //初始化检索对象
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
 
}

#pragma mark - MAMapViewDelegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if (annotation == _destinationPoint)
    {
        //如果是用作导航的，还是用大头针
        static NSString *reuseIndetifier = @"startAnnotationReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        
        return annotationView;
    }

    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        annotationView *annotationVie = (annotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationVie == nil)
        {
            annotationVie = [[annotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        //坐标图的设置
        annotationVie.image = [UIImage imageNamed:@"restaurant"];
        //坐标图的偏移
        annotationVie.centerOffset = CGPointMake(0, -10);
        //设置为no，自己设计弹出气泡的样子
        annotationVie.canShowCallout = NO;
        
        return annotationVie;
    }
    
    return nil;
}


/*!
 • 获取当前用户经纬度:使用mapView的回调方法
 @brief 位置或者设备方向更新后，会调用此函数, 这个回调已废弃由 -(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation 来替代
 @param mapView 地图View
 @param userLocation 用户定位信息(包括位置与设备方向等数据)
 */
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation  updatingLocation:(BOOL)updatingLocation{
    
    NSLog(@"userLocation: %@", userLocation.location);
    _currentLocation = [userLocation.location copy];
}

//逆地理编码
//• 发起搜索请求
- (void)reGeoAction
{
    if (_currentLocation)
    {
        AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];
        request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude
                                                    longitude:_currentLocation.coordinate.longitude];
        [_search AMapReGoecodeSearch:request];
} }
//• 逆地理编码
//• 搜索回调
- (void)searchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"request :%@, error :%@", request, error);
}
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:
(AMapReGeocodeSearchResponse *)response
{
    NSLog(@"response :%@", response);
    NSString *title = response.regeocode.addressComponent.city;
    if (title.length == 0)
    {
        title = response.regeocode.addressComponent.province;
    }
    _mapView.userLocation.title = title;//城市地址
    _mapView.userLocation.subtitle = response.regeocode.formattedAddress;//详细地址
}
//• 在选中用户位置annotation时弹出当前地址
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view
{
    // 选中定位annotation的时候进 逆地理编码查询
    if ([view.annotation isKindOfClass:[MAUserLocation class]])
    {
        [self reGeoAction];

    }
}

//实现POI搜索对应的回调函数
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if(response.pois.count == 0)
    {
        return;
    }
    
    NSLog(@"request:%@" , request);
    NSLog(@"response:%@" , response);
    if (response.pois.count > 0) {
        _poins = response.pois;
        [_tableViews reloadData];
        
        //清除标签
        [_mapView removeAnnotations:_anonatation];
        [_anonatation removeAllObjects];
    }
}

#pragma mark - UITableViewDataSource
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    AMapPOI *poi = _poins[indexPath.row];
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    return cell;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _poins.count;
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //为点击的poi点添加标注
    AMapPOI *poi = _poins[indexPath.row];
    
    MAPointAnnotation *annotation = [[MAPointAnnotation alloc]init];
    
    annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
    annotation.title = poi.name;
    annotation.subtitle = poi.address;
    
    [_mapView addAnnotation:annotation];
    [_anonatation addObject:annotation];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
