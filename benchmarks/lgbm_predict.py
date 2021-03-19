import datetime
import json
import logging

from xdata_prov.client import Api
        

def main():

    # Settings
    logging.basicConfig(level=logging.INFO,
                        format='[%(asctime)s] %(message)s',
                        datefmt='%H:%M:%S')
    target='chiba'
    kinds = ['train', 'predict', 'model', 'evaluate', 'result']
    ddc_name = {kind: f'ddc:lgbm_bench_{target}_{kind}' for kind in kinds}
    table_name = {
        'train': f'public.lgbm_bench_{target}_train_verify',
        'model': f'public.lgbm_bench_{target}_model_verify',
        'predict': f'public.lgbm_bench_{target}_predict_verify'
    }

    # Begin session
    api = Api()  # Set username, password and endpoint from ENV vars
    sessions = api.get_session_list(show_all=False)
    logging.info('Begin session')
    if len(sessions) > 0:
        api.resume_session()
    else:
        api.begin_session()
    logging.info('Current session: \'{}\''.format(api.get_session_token()))

    # Set dDC for model data
    logging.info('Set dDC to the LGBM model table')
    if api.resolve_ddc(ddc=ddc_name['model']) is None:
        api.set_ddc(ddc=ddc_name['model'], table=table_name['model'],
                    ddc_type='user')
        api.commit(ddc=ddc_name['model'])
    else:
        logging.info('  -- reuse existing ddc')

    # Set dDC for prediction data
    logging.info('Set dDC to the LGBM prediction data table')
    if api.resolve_ddc(ddc=ddc_name['predict']) is None:
        api.set_ddc(ddc=ddc_name['predict'], table=table_name['predict'],
                    ddc_type='user')
        api.commit(ddc=ddc_name['predict'])
    else:
        logging.info('  -- reuse existing ddc')

    # LGBM Prediction

    ## Build parameter
    lgbm_prediction_params = {
        'change_conditions': [
            {'rank': 0, 'index': 3, 'threshold': 0.06},
            {'rank': 1, 'index': 3, 'threshold': 0.08},
            {'rank': 2, 'index': 3, 'threshold': 0.06},
            {'rank': 3, 'index': 3, 'threshold': 0.10},
            {'rank': 4, 'index': 3, 'threshold': 0.06},
            {'rank': 5, 'index': 3, 'threshold': 0.10}
        ],
        'hatsurei_confidence': [
            [7.50000000e+01, 9.50000000e+01, 2.37467611e-03],
            [6.00000000e+01, 2.00000000e+01, 1.39599413e-02],
            [7.00000000e+01, 1.50000000e+01, 2.61480186e-02],
            [6.50000000e+01, 1.50000000e+01, 3.67448585e-02],
            [6.50000000e+01, 3.00000000e+01, 5.21031137e-02],
            [7.00000000e+01, 3.00000000e+01, 5.96198665e-02],
            [6.00000000e+01, 3.00000000e+01, 5.68293456e-02],
            [5.00000000e+01, 3.00000000e+01, 5.42171215e-02]
        ],
        'total_probability': [
            0.011, 0.032, 0.055, 0.091, 0.148,
	    0.231, 0.35 , 0.448, 0.494, 0.672
        ]
    }
    lgbm_params = {
        'area_name': 'chiba',
        'test_date': '2020-09-11 18:00:00+09',
        'rank_time': 3,
        'change_time': 9,
        'min_rank': 3,
        'max_rank': 5,
        'predict': lgbm_prediction_params
    }
    params = {
        'output_ddc': ddc_name['result'],
        'output_mode': 'overwrite',
        'model_ddc': ddc_name['model'],
        'input_ddc': ddc_name['predict'],
        'param_json': json.dumps(lgbm_params)
    }

    ## Call API (async)
    logging.info(f"Apply predict_lgbm ({target})")
    ddc = api.process(api_method='predict_lgbm', api_params=params)

    
    ## Wait
    logging.info("Please wait until the server finishes the calculation"
                 " for '{}'".format(ddc['long_form']))
    api.wait_ddc_calculation(ddc=ddc['long_form'])
    logging.info("Done")

    ## Commit and end session
    # api.commit()
    api.rollback()
    api.end_session()


if __name__ == '__main__':
    main()
